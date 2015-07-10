//
//  AMCoreAudioHardware.swift
//  AMCoreAudio
//
//  Created by Ruben on 7/9/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation
import AudioToolbox.AudioServices

public protocol AMCoreAudioHardwareDelegate: class {
    /*!
        Called whenever the list of hardware devices and device subdevices changes.
        (i.e., devices that are part of Aggregate Devices or Multi-Output devices.)
    */
    func hardwareDeviceListChanged(audioHardware: AMCoreAudioHardware)

    /*!
        Called whenever the default input device changes.
    */
    func hardwareDefaultInputDeviceChanged(audioHardware: AMCoreAudioHardware)

    /*!
        Called whenever the default output device changes.
    */
    func hardwareDefaultOutputDeviceChanged(audioHardware: AMCoreAudioHardware)

    /*!
        Called whenever the default system device changes.
    */
    func hardwareDefaultSystemDeviceChanged(audioHardware: AMCoreAudioHardware)
}

final public class AMCoreAudioHardware: NSObject {

    /*!
    A delegate conforming to the AMCoreAudioDeviceDelegate protocol.
    */
    weak var delegate: AMCoreAudioHardwareDelegate? {
        didSet {
            if self.delegate != nil {
                self.registerForNotifications()
            } else {
                self.unregisterForNotifications()
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
        let address: AudioObjectPropertyAddress = inAddresses.memory

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
