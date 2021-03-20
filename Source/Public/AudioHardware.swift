//
//  AudioHardware.swift
//  AMCoreAudio
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
public final class AudioHardware {
    /// Returns a singleton `AudioHardware` instance.
    public static let sharedInstance = AudioHardware()

    private var allKnownDevices = [AudioDevice]()
    private var isRegisteredForNotifications = false

    private lazy var propertyListenerBlock: AudioObjectPropertyListenerBlock = { [weak self] (_, inAddresses) -> Void in
        guard let strongSelf = self else { return }

        let address = inAddresses.pointee
        let notificationCenter = NotificationCenter.default

        switch address.mSelector {
        case kAudioObjectPropertyOwnedObjects:
            // Get the latest device list
            let latestDeviceList = AudioDevice.allDevices()

            let addedDevices = latestDeviceList.filter { (audioDevice) -> Bool in
                !(self?.allKnownDevices.contains { $0 == audioDevice } ?? false)
            }

            let removedDevices = self?.allKnownDevices.filter { (audioDevice) -> Bool in
                !(latestDeviceList.contains { $0 == audioDevice })
            } ?? []

            // Add new devices
            for device in addedDevices {
                self?.add(device: device)
            }

            // Remove old devices
            for device in removedDevices {
                self?.remove(device: device)
            }

            let userInfo: [AnyHashable: Any] = [
                "addedDevices": addedDevices,
                "removedDevices": removedDevices
            ]

            notificationCenter.post(name: Notifications.deviceListChanged.name, object: strongSelf, userInfo: userInfo)
        case kAudioHardwarePropertyDefaultInputDevice:
            notificationCenter.post(name: Notifications.defaultInputDeviceChanged.name, object: strongSelf)
        case kAudioHardwarePropertyDefaultOutputDevice:
            notificationCenter.post(name: Notifications.defaultOutputDeviceChanged.name, object: strongSelf)
        case kAudioHardwarePropertyDefaultSystemOutputDevice:
            notificationCenter.post(name: Notifications.defaultSystemOutputDeviceChanged.name, object: strongSelf)
        default:
            break
        }
    }

    // MARK: - Lifecycle Functions

    deinit {
        disableDeviceMonitoring()
    }

    // MARK: - Public Functions

    /// Enables device monitoring so events like the ones below are generated:
    ///
    /// - added or removed device
    /// - new default input device
    /// - new default output device
    /// - new default system output device
    ///
    /// - SeeAlso: `disableDeviceMonitoring()`
    public func enableDeviceMonitoring() {
        registerForNotifications()

        for device in AudioDevice.allDevices() {
            add(device: device)
        }
    }

    /// Disables device monitoring.
    ///
    /// - SeeAlso: `enableDeviceMonitoring()`
    public func disableDeviceMonitoring() {
        for device in allKnownDevices {
            remove(device: device)
        }

        unregisterForNotifications()
    }

    // MARK: - Private Functions

    private func add(device: AudioDevice) {
        allKnownDevices.append(device)
    }

    private func remove(device: AudioDevice) {
        allKnownDevices.removeAll { $0 == device }
    }

    // MARK: - Notification Book-keeping

    private func registerForNotifications() {
        if isRegisteredForNotifications {
            unregisterForNotifications()
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)
        let err = AudioObjectAddPropertyListenerBlock(systemObjectID, &address, propertyListenerQueue, propertyListenerBlock)

        if noErr != err {
            os_log("Error on AudioObjectAddPropertyListenerBlock: %@.", log: .default, type: .debug, err)
        }

        isRegisteredForNotifications = noErr == err
    }

    private func unregisterForNotifications() {
        guard isRegisteredForNotifications else { return }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)
        let err = AudioObjectRemovePropertyListenerBlock(systemObjectID, &address, propertyListenerQueue, propertyListenerBlock)

        if noErr != err {
            os_log("Error on AudioObjectRemovePropertyListenerBlock: %@.", log: .default, type: .debug, err)
        }

        isRegisteredForNotifications = noErr != err
    }
}
