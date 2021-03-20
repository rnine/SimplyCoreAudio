//
//  AudioHardware.swift
//  SimplyCoreAudio
//
//  Created by Ruben on 7/9/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import CoreAudio.AudioHardwareBase
import Foundation
import os.log

/// This class allows subscribing to hardware-related audio notifications.
///
/// For a comprehensive list of supported notifications, see `AudioHardwareEvent`.
final class AudioHardware {
    // MARK: - Fileprivate Properties

    fileprivate var allKnownDevices = [AudioDevice]()
    fileprivate var isRegisteredForNotifications = false

    // MARK: - Internal Functions

    /// Enables device monitoring so events like the ones below are generated:
    ///
    /// - added or removed device
    /// - new default input device
    /// - new default output device
    /// - new default system output device
    ///
    /// - SeeAlso: `disableDeviceMonitoring()`
    func enableDeviceMonitoring() {
        registerForNotifications()

        for device in AudioDevice.allDevices() {
            add(device: device)
        }
    }

    /// Disables device monitoring.
    ///
    /// - SeeAlso: `enableDeviceMonitoring()`
    func disableDeviceMonitoring() {
        for device in allKnownDevices {
            remove(device: device)
        }

        unregisterForNotifications()
    }
}

// MARK: - Fileprivate Functions

fileprivate extension AudioHardware {
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
                              inAddresses : UnsafePointer<AudioObjectPropertyAddress>,
                              clientData: Optional<UnsafeMutableRawPointer>) -> Int32 {
    let _self = Unmanaged<AudioHardware>.fromOpaque(clientData!).takeUnretainedValue()
    let address = inAddresses.pointee
    let notificationCenter = NotificationCenter.default

    switch address.mSelector {
    case kAudioObjectPropertyOwnedObjects:
        // Get the latest device list
        let latestDeviceList = AudioDevice.allDevices()

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
            "added": addedDevices,
            "removed": removedDevices
        ]

        notificationCenter.post(name: Notifications.deviceListChanged.name, object: _self, userInfo: userInfo)
    case kAudioHardwarePropertyDefaultInputDevice:
        notificationCenter.post(name: Notifications.defaultInputDeviceChanged.name, object: _self)
    case kAudioHardwarePropertyDefaultOutputDevice:
        notificationCenter.post(name: Notifications.defaultOutputDeviceChanged.name, object: _self)
    case kAudioHardwarePropertyDefaultSystemOutputDevice:
        notificationCenter.post(name: Notifications.defaultSystemOutputDeviceChanged.name, object: _self)
    default:
        break
    }

    return noErr
}
