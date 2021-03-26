//
//  SimplyCoreAudio.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import Foundation
import os.log

/// `SimplyCoreAudio` provides convenient audio hardware-related functions (e.g. obtaining all devices managed by
/// Core Audio) and allows audio hardware-related notifications to work. Additionally, you may create and remove
/// aggregate devices using this class.
///
/// - Important: If you are interested in receiving hardware-related notifications, remember to keep a strong reference
/// to an object of this class.
///
/// However, *do not* keep more than one instance of this class at the same time to avoid receiving duplicated
/// notifications.
///
/// As soon as the last remaining instance of this class is deallocated, hardware-related notifications will no longer
/// be delivered.
///
/// We could have designed this class to always return a shared instance, but ultimately decided to allow developers
/// total control so they have the chance to cleanup any resources used by `SimplyCoreAudio` such as hardware-related
/// Core Audio property listeners by simply deallocating any instances of this class.
public final class SimplyCoreAudio {
    // MARK: - Public Properties

    /// All the audio device identifiers currently available.
    ///
    /// - Note: This list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioObjectID` values.
    public var allDeviceIDs: [AudioObjectID] {
        hardware.allDeviceIDs
    }

    /// All the audio devices currently available.
    ///
    /// - Note: This list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allDevices: [AudioDevice] {
        hardware.allDevices
    }

    /// All the devices that have at least one input.
    ///
    /// - Note: This list may also include *Aggregate* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allInputDevices: [AudioDevice] {
        hardware.allInputDevices
    }

    /// All the devices that have at least one output.
    ///
    /// - Note: The list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allOutputDevices: [AudioDevice] {
        hardware.allOutputDevices
    }

    /// All the devices that support input and output.
    ///
    /// - Note: The list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allIODevices: [AudioDevice] {
        hardware.allIODevices
    }

    /// All the devices that are real devices — not aggregate ones.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allNonAggregateDevices: [AudioDevice] {
        hardware.allNonAggregateDevices
    }

    /// All the devices that are aggregate devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allAggregateDevices: [AudioDevice] {
        hardware.allAggregateDevices
    }

    /// The default input device.
    ///
    /// - Returns: *(optional)* An `AudioDevice`.
    public var defaultInputDevice: AudioDevice? {
        hardware.defaultInputDevice
    }

    /// The default output device.
    ///
    /// - Returns: *(optional)* An `AudioDevice`.
    public var defaultOutputDevice: AudioDevice? {
        hardware.defaultOutputDevice
    }

    /// The default system output device.
    ///
    /// - Returns: *(optional)* An `AudioDevice`.
    public var defaultSystemOutputDevice: AudioDevice? {
        hardware.defaultSystemOutputDevice
    }

    // MARK: - Private Properties

    private let hardware = AudioHardware()

    // MARK: - Lifecycle

    init() {
        hardware.enableDeviceMonitoring()
    }

    deinit {
        hardware.disableDeviceMonitoring()
    }
}

// MARK: - Public Functions

public extension SimplyCoreAudio {
    // MARK: - Create and Destroy Aggregate Devices

    /// This routine creates a new Aggregate AudioDevice
    ///
    /// - Parameter masterDeviceUID: An audio device. This will also be the clock source.
    /// - Parameter secondDeviceUID: An audio device.
    ///
    /// - Returns *(optional)* An aggregate `AudioDevice` if one can be created.
    func createAggregateDevice(masterDevice: AudioDevice,
                               secondDevice: AudioDevice?,
                               named name: String,
                               uid: String) -> AudioDevice?
    {
        guard let masterDeviceUID = masterDevice.uid else { return nil }

        var deviceList: [[String: Any]] = [
            [kAudioSubDeviceUIDKey: masterDeviceUID]
        ]

        // make sure same device isn't added twice
        if let secondDeviceUID = secondDevice?.uid, secondDeviceUID != masterDeviceUID {
            deviceList.append([kAudioSubDeviceUIDKey: secondDeviceUID])
        }

        let desc: [String: Any] = [
            kAudioAggregateDeviceNameKey: name,
            kAudioAggregateDeviceUIDKey: uid,
            kAudioAggregateDeviceSubDeviceListKey: deviceList,
            kAudioAggregateDeviceMasterSubDeviceKey: masterDeviceUID
        ]

        var deviceID: AudioDeviceID = 0
        let error = AudioHardwareCreateAggregateDevice(desc as CFDictionary, &deviceID)

        guard error == noErr else {
            os_log("Failed creating aggregate device with error: %d.", log: .default, type: .debug, error)
            return nil
        }

        return AudioDevice.lookup(by: deviceID)
    }

    /// Destroy the given AudioAggregateDevice.
    ///
    /// The actual destruction of the device is asynchronous and may take place after
    /// the call to this routine has returned.
    /// - Parameter id: The AudioObjectID of the AudioAggregateDevice to destroy.
    /// - Returns An OSStatus indicating success or failure.
    func removeAggregateDevice(id deviceID: AudioObjectID) -> OSStatus {
        AudioHardwareDestroyAggregateDevice(deviceID)
    }
}
