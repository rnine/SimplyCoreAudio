//  AudioDevice+Aggregate.swift
//  Created by Ryan Francesconi on 2/24/21.
//  Copyright © 2021 9Labs. All rights reserved.

import AudioToolbox.AudioServices
import os.log

public extension AudioDevice {
    /// - Returns: `true` if this device is an aggregate one, `false` otherwise.
    func isAggregateDevice() -> Bool {
        guard let aggregateDevices = ownedAggregateDevices() else { return false }
        return !aggregateDevices.isEmpty
    }

    /// All the subdevices of this aggregate device
    ///
    /// - Returns: An array of `AudioDevice` objects.
    func ownedAggregateDevices() -> [AudioDevice]? {
        guard let ownedObjectIDs = ownedObjectIDs() else { return nil }

        let ownedDevices = ownedObjectIDs.compactMap { (id) -> AudioDevice? in
            AudioDevice.lookup(by: id)
        }
        // only aggregates have non nil owned UIDs. I think?
        return ownedDevices.filter { $0.uid != nil }
    }

    /// All the subdevices of this aggregate device that support input
    ///
    /// - Returns: An array of `AudioDevice` objects.
    func ownedAggregateInputDevices() -> [AudioDevice]? {
        ownedAggregateDevices()?.filter {
            guard let channels = $0.layoutChannels(direction: .recording) else { return false }
            return channels > 0
        }
    }

    /// All the subdevices of this aggregate device that support output
    ///
    /// - Returns: An array of `AudioDevice` objects.
    func ownedAggregateOutputDevices() -> [AudioDevice]? {
        ownedAggregateDevices()?.filter {
            guard let channels = $0.layoutChannels(direction: .playback) else { return false }
            return channels > 0
        }
    }

    // MARK: - Create and Destroy Aggregate Devices

    /// This routine creates a new Aggregate AudioDevice
    ///
    /// - Parameter masterDeviceUID: An audio device unique identifier. This will also be the clock source.
    /// - Parameter secondDeviceUID: An audio device unique identifier
    ///
    /// - Returns *(optional)* An aggregate `AudioDevice` if one can be created.
    static func createAggregateDevice(masterDeviceUID: String,
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
    static func removeAggregateDevice(id deviceID: AudioObjectID) -> OSStatus {
        AudioHardwareDestroyAggregateDevice(deviceID)
    }
}
