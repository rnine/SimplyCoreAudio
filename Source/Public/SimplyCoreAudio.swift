//
//  SimplyCoreAudio.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import AudioToolbox.AudioServices
import os.log

public final class SimplyCoreAudio {
    // MARK: - Public Properties

    /// All the audio device identifiers currently available in the system.
    ///
    /// - Note: This list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioObjectID` values.
    public var allDeviceIDs: [AudioObjectID] {
        hardware.allDeviceIDs
    }

    /// All the audio devices currently available in the system.
    ///
    /// - Note: This list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allDevices: [AudioDevice] {
        hardware.allDevices
    }

    /// All the devices in the system that have at least one input.
    ///
    /// - Note: This list may also include *Aggregate* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allInputDevices: [AudioDevice] {
        hardware.allInputDevices
    }

    /// All the devices in the system that have at least one output.
    ///
    /// - Note: The list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allOutputDevices: [AudioDevice] {
        hardware.allOutputDevices
    }

    /// All the devices in the system that support input and output.
    ///
    /// - Note: The list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allIODevices: [AudioDevice] {
        hardware.allIODevices
    }

    /// All the devices in the system that are real devices - not aggregate ones.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allNonAggregateDevices: [AudioDevice] {
        hardware.allNonAggregateDevices
    }

    /// All the devices in the system that are aggregate devices.
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
    /// - Parameter masterDeviceUID: An audio device unique identifier. This will also be the clock source.
    /// - Parameter secondDeviceUID: An audio device unique identifier
    ///
    /// - Returns *(optional)* An aggregate `AudioDevice` if one can be created.
    func createAggregateDevice(masterDeviceUID: String,
                                      secondDeviceUID: String?,
                                      named name: String,
                                      uid: String) -> AudioDevice?
    {
        var deviceList: [[String: Any]] = [
            [kAudioSubDeviceUIDKey: masterDeviceUID]
        ]

        // make sure same device isn't added twice
        if let secondDeviceUID = secondDeviceUID,
           secondDeviceUID != masterDeviceUID
        {
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
