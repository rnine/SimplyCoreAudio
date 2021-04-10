//
//  SimplyCoreAudio+Aggregate.swift
//
//
//  Created by Ruben Nine on 4/4/21.
//

import CoreAudio
import Foundation
import os.log

// MARK: - Create and Destroy Aggregate Devices

public extension SimplyCoreAudio {
    /// This routine creates a new aggregate audio device.
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
            [kAudioSubDeviceUIDKey: masterDeviceUID],
        ]

        // make sure same device isn't added twice
        if let secondDeviceUID = secondDevice?.uid, secondDeviceUID != masterDeviceUID {
            deviceList.append([kAudioSubDeviceUIDKey: secondDeviceUID])
        }

        let desc: [String: Any] = [
            kAudioAggregateDeviceNameKey: name,
            kAudioAggregateDeviceUIDKey: uid,
            kAudioAggregateDeviceSubDeviceListKey: deviceList,
            kAudioAggregateDeviceMasterSubDeviceKey: masterDeviceUID,
        ]

        var deviceID: AudioDeviceID = 0
        let error = AudioHardwareCreateAggregateDevice(desc as CFDictionary, &deviceID)

        guard error == noErr else {
            OSLog.error("Failed creating aggregate device with error:", error)
            return nil
        }

        return AudioDevice.lookup(by: deviceID)
    }

    /// Destroy the given audio aggregate device.
    ///
    /// The actual destruction of the device is asynchronous and may take place after
    /// the call to this routine has returned.
    ///
    /// - Parameter id: The `AudioObjectID` of the audio aggregate device to destroy.
    /// - Returns An `OSStatus` indicating success or failure.
    func removeAggregateDevice(id deviceID: AudioObjectID) -> OSStatus {
        AudioHardwareDestroyAggregateDevice(deviceID)
    }
}
