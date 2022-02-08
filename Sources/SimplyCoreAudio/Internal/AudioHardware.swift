//
//  AudioHardware.swift
//
//  Created by Ruben Nine on 7/9/15.
//

import CoreAudio
import Foundation
import os.log

final class AudioHardware {
    // MARK: - Fileprivate Properties

    fileprivate var allKnownDevices = [AudioDevice]()
    fileprivate var isRegisteredForNotifications = false

    // MARK: - Internal Functions

    func enableDeviceMonitoring() {
        registerForNotifications()

        for device in allDevices {
            add(device: device)
        }
    }

    func disableDeviceMonitoring() {
        for device in allKnownDevices {
            remove(device: device)
        }

        unregisterForNotifications()
    }

    var allDeviceIDs: [AudioObjectID] {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: Element.main.asPropertyElement
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)
        var allIDs = [AudioObjectID]()
        let status = AudioDevice.getPropertyDataArray(systemObjectID, address: address, value: &allIDs, andDefaultValue: 0)

        return noErr == status ? allIDs : []
    }

    var allDevices: [AudioDevice] {
        allDeviceIDs.compactMap { AudioDevice.lookup(by: $0) }
    }

    var allInputDevices: [AudioDevice] {
        allDevices.filter { $0.channels(scope: .input) > 0 }
    }

    var allOutputDevices: [AudioDevice] {
        allDevices.filter { $0.channels(scope: .output) > 0 }
    }

    var allIODevices: [AudioDevice] {
        allDevices.filter {
            $0.channels(scope: .input) > 0 && $0.channels(scope: .output) > 0
        }
    }

    var allNonAggregateDevices: [AudioDevice] {
        allDevices.filter { !$0.isAggregateDevice }
    }

    var allAggregateDevices: [AudioDevice] {
        allDevices.filter { $0.isAggregateDevice }
    }

    var defaultInputDevice: AudioDevice? {
        defaultDevice(of: kAudioHardwarePropertyDefaultInputDevice)
    }

    var defaultOutputDevice: AudioDevice? {
        defaultDevice(of: kAudioHardwarePropertyDefaultOutputDevice)
    }

    var defaultSystemOutputDevice: AudioDevice? {
        defaultDevice(of: kAudioHardwarePropertyDefaultSystemOutputDevice)
    }
}

// MARK: - Fileprivate Functions

fileprivate extension AudioHardware {
    func defaultDevice(of type: AudioObjectPropertySelector) -> AudioDevice? {
        let address = AudioDevice.address(selector: type)
        var deviceID = AudioDeviceID()
        let status = AudioDevice.getPropertyData(AudioObjectID(kAudioObjectSystemObject), address: address, andValue: &deviceID)

        return noErr == status ? AudioDevice.lookup(by: deviceID) : nil
    }

    func add(device: AudioDevice) {
        allKnownDevices.append(device)
    }

    func remove(device: AudioDevice) {
        allKnownDevices.removeAll { $0 == device }
    }

    // MARK: - Notification Book-keeping

    func registerForNotifications() {
        if isRegisteredForNotifications {
            unregisterForNotifications()
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        if noErr != AudioObjectAddPropertyListener(systemObjectID, &address, propertyListener, selfPtr) {
            os_log("Unable to add property listener for systemObjectID: %@.", systemObjectID)
        } else {
            isRegisteredForNotifications = true
        }
    }

    func unregisterForNotifications() {
        guard isRegisteredForNotifications else { return }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        if noErr != AudioObjectRemovePropertyListener(systemObjectID, &address, propertyListener, selfPtr) {
            os_log("Unable to remove property listener for systemObjectID: %@.", systemObjectID)
        } else {
            isRegisteredForNotifications = false
        }
    }
}

// MARK: - C Convention Functions

private func propertyListener(objectID: UInt32,
                              numInAddresses: UInt32,
                              inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
                              clientData: Optional<UnsafeMutableRawPointer>) -> Int32 {
    let _self = Unmanaged<AudioHardware>.fromOpaque(clientData!).takeUnretainedValue()
    let address = inAddresses.pointee
    let notificationCenter = NotificationCenter.default

    switch address.mSelector {
    case kAudioObjectPropertyOwnedObjects:
        // Get the latest device list
        let latestDeviceList = _self.allDevices

        let addedDevices = latestDeviceList.filter { (audioDevice) -> Bool in
            !(_self.allKnownDevices.contains { $0 == audioDevice })
        }

        let removedDevices = _self.allKnownDevices.filter { (audioDevice) -> Bool in
            !(latestDeviceList.contains { $0 == audioDevice })
        }

        // Add new devices
        for device in addedDevices {
            _self.add(device: device)
        }

        // Remove old devices
        for device in removedDevices {
            _self.remove(device: device)
        }

        let userInfo: [AnyHashable: Any] = [
            "addedDevices": addedDevices,
            "removedDevices": removedDevices,
        ]

        DispatchQueue.main.async { notificationCenter.post(name: .deviceListChanged, object: _self, userInfo: userInfo) }
    case kAudioHardwarePropertyDefaultInputDevice:
        DispatchQueue.main.async { notificationCenter.post(name: .defaultInputDeviceChanged, object: _self) }
    case kAudioHardwarePropertyDefaultOutputDevice:
        DispatchQueue.main.async { notificationCenter.post(name: .defaultOutputDeviceChanged, object: _self) }
    case kAudioHardwarePropertyDefaultSystemOutputDevice:
        DispatchQueue.main.async { notificationCenter.post(name: .defaultSystemOutputDeviceChanged, object: _self) }
    default:
        break
    }

    return kAudioHardwareNoError
}
