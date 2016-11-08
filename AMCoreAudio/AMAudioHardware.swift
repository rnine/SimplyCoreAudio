//
//  AMAudioHardware.swift
//  AMCoreAudio
//
//  Created by Ruben on 7/9/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation
import AudioToolbox.AudioServices

///// `AMAudioHardwareEvent` enum
public enum AMAudioHardwareEvent: AMEvent {
    /**
        Called whenever the list of hardware devices and device subdevices changes.
        (i.e., devices that are part of *Aggregate* or *Multi-Output* devices.)
     */
    case deviceListChanged(addedDevices: [AMAudioDevice], removedDevices: [AMAudioDevice])

    /**
        Called whenever the default input device changes.
     */
    case defaultInputDeviceChanged(audioDevice: AMAudioDevice)

    /**
        Called whenever the default output device changes.
     */
    case defaultOutputDeviceChanged(audioDevice: AMAudioDevice)

    /**
        Called whenever the default system output device changes.
     */
    case defaultSystemOutputDeviceChanged(audioDevice: AMAudioDevice)
}

/**
    `AMAudioHardware`

    This class allows subscribing to hardware-related audio notifications.

    For a comprehensive list of supported notifications, see `AMAudioHardwareDelegate`.
 */
final public class AMAudioHardware: NSObject {

    /**
        Returns a singleton `AMAudioHardware` instance.
    */
    public static let sharedInstance = AMAudioHardware()

    /**
        An auto-maintained array of all the audio devices currently available in the system.

        - Note: This list may also include *Aggregate* and *Multi-Output* devices.

        - Returns: An array of `AMAudioDevice` objects.
     */
    private var allKnownDevices = [AMAudioDevice]()

    private var isRegisteredForNotifications = false

    private lazy var notificationsQueue: DispatchQueue = {
        return DispatchQueue(label: "io.9labs.AMCoreAudio.hardwareNotifications", attributes: .concurrent)
    }()

    private lazy var propertyListenerBlock: AudioObjectPropertyListenerBlock = { [weak self] (inNumberAddresses, inAddresses) -> Void in
        let address = inAddresses.pointee
        let notificationCenter = AMNotificationCenter.defaultCenter

        switch address.mSelector {
        case kAudioObjectPropertyOwnedObjects:
            // Get the latest device list
            let latestDeviceList = AMAudioDevice.allDevices()

            let addedDevices = latestDeviceList.filter { (audioDevice) -> Bool in
                let isContained = (self?.allKnownDevices.filter({ (oldAudioDevice) -> Bool in
                    return oldAudioDevice == audioDevice
                }) ?? []).count > 0

                return !isContained
            }

            let removedDevices = self?.allKnownDevices.filter { (audioDevice) -> Bool in
                let isContained = latestDeviceList.filter({ (oldAudioDevice) -> Bool in
                    return oldAudioDevice == audioDevice
                }).count > 0

                return !isContained
            }

            // Add new devices
            addedDevices.forEach { (device) in
                self?.addDevice(device)
            }
            
            // Remove old devices
            removedDevices?.forEach { (device) in
                self?.removeDevice(device)
            }

            notificationCenter.publish(AMAudioHardwareEvent.deviceListChanged(
                addedDevices: addedDevices,
                removedDevices: removedDevices ?? []
            ))
        case kAudioHardwarePropertyDefaultInputDevice:
            if let audioDevice = AMAudioDevice.defaultInputDevice() {
                notificationCenter.publish(AMAudioHardwareEvent.defaultInputDeviceChanged(audioDevice: audioDevice))
            }
        case kAudioHardwarePropertyDefaultOutputDevice:
            if let audioDevice = AMAudioDevice.defaultOutputDevice() {
                notificationCenter.publish(AMAudioHardwareEvent.defaultOutputDeviceChanged(audioDevice: audioDevice))
            }
        case kAudioHardwarePropertyDefaultSystemOutputDevice:
            if let audioDevice = AMAudioDevice.defaultSystemOutputDevice() {
                notificationCenter.publish(AMAudioHardwareEvent.defaultSystemOutputDeviceChanged(audioDevice: audioDevice))
            }
        default:
            break
        }
    }

    // MARK: - Public Functions

    internal override init() {
        super.init()
    }

    deinit {
        disableDeviceMonitoring()
    }

    /**
        Enables device monitoring so events like the ones below are generated:
     
        - added or removed device
        - new default input device
        - new default output device
        - new default system output device

        - SeeAlso: disableDeviceMonitoring()
     */
    internal func enableDeviceMonitoring() {
        registerForNotifications()

        let allDevices = AMAudioDevice.allDevices()

        allDevices.forEach { (device) in
            addDevice(device)
        }
    }

    /**
        Disables device monitoring.
     
        - SeeAlso: enableDeviceMonitoring()
     */
    internal func disableDeviceMonitoring() {
        allKnownDevices.forEach { (device) in
            removeDevice(device)
        }

        unregisterForNotifications()
    }

    // MARK: - Private Functions

    private func addDevice(_ device: AMAudioDevice) {
        allKnownDevices.append(device)
    }

    private func removeDevice(_ device: AMAudioDevice) {
        if let idx = allKnownDevices.index(of: device) {
            allKnownDevices.remove(at: idx)
        }
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

        let err = AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, notificationsQueue, propertyListenerBlock)

        if noErr != err {
            print("Error on AudioObjectAddPropertyListenerBlock: \(err)")
        }

        isRegisteredForNotifications = noErr == err
    }

    private func unregisterForNotifications() {
        if isRegisteredForNotifications {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertySelectorWildcard,
                mScope: kAudioObjectPropertyScopeWildcard,
                mElement: kAudioObjectPropertyElementWildcard
            )

            let err = AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, notificationsQueue, propertyListenerBlock)

            if noErr != err {
                print("Error on AudioObjectRemovePropertyListenerBlock: \(err)")
            }

            isRegisteredForNotifications = noErr != err
        }
    }
}
