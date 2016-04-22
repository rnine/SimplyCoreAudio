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
    case DeviceListChanged(addedDevices: [AMAudioDevice], removedDevices: [AMAudioDevice])

    /**
        Called whenever the default input device changes.
     */
    case DefaultInputDeviceChanged(audioDevice: AMAudioDevice)

    /**
        Called whenever the default output device changes.
     */
    case DefaultOutputDeviceChanged(audioDevice: AMAudioDevice)

    /**
        Called whenever the default system output device changes.
     */
    case DefaultSystemOutputDeviceChanged(audioDevice: AMAudioDevice)
}

/**
    `AMAudioHardware`

    This class allows subscribing to hardware-related audio notifications.

    For a comprehensive list of supported notifications, see `AMAudioHardwareDelegate`.
 */
final public class AMAudioHardware: NSObject {

    public static let sharedInstance = AMAudioHardware()

    /**
        An auto-maintained array of all the audio devices currently available in the system.

        - Note: This list may also include *Aggregate* and *Multi-Output* devices.

        - Returns: An array of `AMAudioDevice` objects.
     */
    private var allKnownDevices = [AMAudioDevice]()

    private var isRegisteredForNotifications = false

    private lazy var notificationsQueue: dispatch_queue_t = {
        return dispatch_queue_create("io.9labs.AMCoreAudio.hardwareNotifications", DISPATCH_QUEUE_CONCURRENT)
    }()

    private lazy var propertyListenerBlock: AudioObjectPropertyListenerBlock = { (inNumberAddresses, inAddresses) -> Void in
        let address = inAddresses.memory
        let notificationCenter = AMNotificationCenter.defaultCenter

        switch address.mSelector {
        case kAudioObjectPropertyOwnedObjects:
            // Get the latest device list
            let latestDeviceList = AMAudioDevice.allDevices()

            let addedDevices = latestDeviceList.filter { (audioDevice) -> Bool in
                let isContained = self.allKnownDevices.filter({ (oldAudioDevice) -> Bool in
                    return oldAudioDevice == audioDevice
                }).count > 0

                return !isContained
            }

            let removedDevices = self.allKnownDevices.filter { (audioDevice) -> Bool in
                let isContained = latestDeviceList.filter({ (oldAudioDevice) -> Bool in
                    return oldAudioDevice == audioDevice
                }).count > 0

                return !isContained
            }

            // Add new devices
            addedDevices.forEach { (device) in
                self.addDevice(device)
            }
            
            // Remove old devices
            removedDevices.forEach { (device) in
                self.removeDevice(device)
            }

            notificationCenter.publish(AMAudioHardwareEvent.DeviceListChanged(
                addedDevices: addedDevices,
                removedDevices: removedDevices
            ))
        case kAudioHardwarePropertyDefaultInputDevice:
            if let audioDevice = AMAudioDevice.defaultInputDevice() {
                notificationCenter.publish(AMAudioHardwareEvent.DefaultInputDeviceChanged(audioDevice: audioDevice))
            }
        case kAudioHardwarePropertyDefaultOutputDevice:
            if let audioDevice = AMAudioDevice.defaultOutputDevice() {
                notificationCenter.publish(AMAudioHardwareEvent.DefaultOutputDeviceChanged(audioDevice: audioDevice))
            }
        case kAudioHardwarePropertyDefaultSystemOutputDevice:
            if let audioDevice = AMAudioDevice.defaultSystemOutputDevice() {
                notificationCenter.publish(AMAudioHardwareEvent.DefaultSystemOutputDeviceChanged(audioDevice: audioDevice))
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
        cleanup()
    }

    /**
        Enables device monitoring so events like the ones below are generated:
     
        - added or removed device
        - new default input device
        - new default output device
        - new system output device

        - SeeAlso: disableDeviceMonitoring()
     */
    public func enableDeviceMonitoring() {
        setup()
    }

    /**
        Disables device monitoring.
     
        - SeeAlso: enableDeviceMonitoring()
     */
    public func disableDeviceMonitoring() {
        cleanup()
    }

    // MARK: - Private Functions

    private func setup() {
        //print("Foo foo")
        registerForNotifications()

        let allDevices = AMAudioDevice.allDevices()

        allDevices.forEach { (device) in
            addDevice(device)
        }
    }

    private func cleanup() {
        allKnownDevices.forEach { (device) in
            removeDevice(device)
        }

        unregisterForNotifications()
    }

    private func addDevice(device: AMAudioDevice) {
        allKnownDevices.append(device)
    }

    private func removeDevice(device: AMAudioDevice) {
        if let idx = allKnownDevices.indexOf(device) {
            allKnownDevices.removeAtIndex(idx)
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
