//
//  AudioDevice+DefaultDevice.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import Foundation

// MARK: - Public Functions & Properties

public extension AudioDevice {
    // MARK: - Default Device Functions

    /// Promotes this device to become the default input device.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setAsDefaultInputDevice() -> Bool {
        setDefaultDevice(kAudioHardwarePropertyDefaultInputDevice)
    }

    /// Promotes this device to become the default output device.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setAsDefaultOutputDevice() -> Bool {
        setDefaultDevice(kAudioHardwarePropertyDefaultOutputDevice)
    }

    /// Promotes this device to become the default system output device.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setAsDefaultSystemDevice() -> Bool {
        setDefaultDevice(kAudioHardwarePropertyDefaultSystemOutputDevice)
    }
}

// MARK: - Private Functions

private extension AudioDevice {
    func setDefaultDevice(_ type: AudioObjectPropertySelector) -> Bool {
        let address = self.address(selector: type)

        var deviceID = UInt32(id)
        let status = setPropertyData(AudioObjectID(kAudioObjectSystemObject), address: address, andValue: &deviceID)

        return noErr == status
    }
}
