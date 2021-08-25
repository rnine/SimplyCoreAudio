//
//  SimplyCoreAudio+Aggregate.swift
//  
//
//  Created by Ruben Nine on 4/4/21.
//

import CoreAudio
import Foundation
import os.log
@_implementationOnly import SimplyCoreAudioC

// MARK: - Create and Destroy Aggregate Devices

public extension SimplyCoreAudio {
    /// This routine creates a new aggregate audio device.
    ///
    /// - Parameter mainDevice: An audio device. This will also be the clock source.
    /// - Parameter secondDevice: An audio device.
    ///
    /// - Returns *(optional)* An aggregate `AudioDevice` if one can be created.
    func createAggregateDevice(mainDevice: AudioDevice,
                               secondDevice: AudioDevice?,
                               named name: String,
                               uid: String) -> AudioDevice?
    {
        guard let mainDeviceUID = mainDevice.uid else { return nil }

        var deviceList: [[String: Any]] = [
            [kAudioSubDeviceUIDKey: mainDeviceUID]
        ]

        // make sure same device isn't added twice
        if let secondDeviceUID = secondDevice?.uid, secondDeviceUID != mainDeviceUID {
            deviceList.append([kAudioSubDeviceUIDKey: secondDeviceUID])
        }

        let desc: [String: Any] = [
            kAudioAggregateDeviceNameKey: name,
            kAudioAggregateDeviceUIDKey: uid,
            kAudioAggregateDeviceSubDeviceListKey: deviceList,
            kAudioAggregateDeviceMainSubDeviceKey: mainDeviceUID
        ]

        var deviceID: AudioDeviceID = 0
        let error = AudioHardwareCreateAggregateDevice(desc as CFDictionary, &deviceID)

        guard error == noErr else {
            os_log("Failed creating aggregate device with error: %d.", log: .default, type: .debug, error)
            return nil
        }

        return AudioDevice.lookup(by: deviceID)
    }
    
    @available(*, deprecated, message: "mainDevice: is preferred spelling for first argument")
    func createAggregateDevice(masterDevice: AudioDevice,
                               secondDevice: AudioDevice?,
                               named name: String,
                               uid: String) -> AudioDevice?
    {
        return createAggregateDevice(mainDevice: masterDevice, secondDevice: secondDevice, named: name, uid: uid)
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
