//
//  AMCoreAudioHardware.swift
//  AMCoreAudio
//
//  Created by Ruben on 7/9/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation
import AudioToolbox.AudioServices

/// `AMCoreAudioHardwareDelegate` protocol
public protocol AMCoreAudioHardwareDelegate: class {

    /**
        Called whenever the list of hardware devices and device subdevices changes.
        (i.e., devices that are part of Aggregate Devices or Multi-Output devices.)
     */
    func hardwareDeviceListChanged(audioHardware: AMCoreAudioHardware)

    /**
        Called whenever the default input device changes.
     */
    func hardwareDefaultInputDeviceChanged(audioHardware: AMCoreAudioHardware)

    /**
        Called whenever the default output device changes.
     */
    func hardwareDefaultOutputDeviceChanged(audioHardware: AMCoreAudioHardware)

    /**
        Called whenever the default system device changes.
     */
    func hardwareDefaultSystemDeviceChanged(audioHardware: AMCoreAudioHardware)
}

/// Optional `AMCoreAudioHardwareDelegate` protocol functions
public extension AMCoreAudioHardwareDelegate {

    func hardwareDeviceListChanged(audioHardware: AMCoreAudioHardware) {}
    func hardwareDefaultInputDeviceChanged(audioHardware: AMCoreAudioHardware) {}
    func hardwareDefaultOutputDeviceChanged(audioHardware: AMCoreAudioHardware) {}
    func hardwareDefaultSystemDeviceChanged(audioHardware: AMCoreAudioHardware) {}
}

/**
    `AMCoreAudioHardware`

    This class allows subscribing to hardware-related audio notifications.

    For a comprehensive list of supported notifications, see `AMCoreAudioHardwareDelegate`.
 */
final public class AMCoreAudioHardware: NSObject {

    /**
        A delegate conforming to the `AMCoreAudioHardwareDelegate` protocol.
     */
    public weak var delegate: AMCoreAudioHardwareDelegate? {
        didSet {
            if delegate != nil {
                registerForNotifications()
            } else {
                unregisterForNotifications()
            }
        }
    }

    deinit {
        delegate = nil
    }

    private var isRegisteredForNotifications = false

    private lazy var notificationsQueue: dispatch_queue_t = {
        return dispatch_queue_create("io.9labs.AMCoreAudio.HW-notifications", DISPATCH_QUEUE_CONCURRENT)
    }()

    private lazy var propertyListenerBlock: AudioObjectPropertyListenerBlock = { (inNumberAddresses, inAddresses) -> Void in
        let address = inAddresses.memory

        switch address.mSelector {
        case kAudioObjectPropertyOwnedObjects:
            self.delegate?.hardwareDeviceListChanged(self)
        case kAudioHardwarePropertyDefaultInputDevice:
            self.delegate?.hardwareDefaultInputDeviceChanged(self)
        case kAudioHardwarePropertyDefaultOutputDevice:
            self.delegate?.hardwareDefaultOutputDeviceChanged(self)
        case kAudioHardwarePropertyDefaultSystemOutputDevice:
            self.delegate?.hardwareDefaultSystemDeviceChanged(self)
        default:
            break
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
