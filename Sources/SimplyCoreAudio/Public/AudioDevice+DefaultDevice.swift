//
//  AudioDevice+DefaultDevice.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import Foundation

// MARK: - Public Functions & Properties

public extension AudioDevice {
    // MARK: - Default Device Properties

    /// Allows getting and setting this device as the default input device.
    var isDefaultInputDevice: Bool {
        get { hardware.defaultInputDevice == self }
        set { _ = setDefaultDevice(kAudioHardwarePropertyDefaultInputDevice) }
    }

    /// Allows getting and setting this device as the default output device.
    var isDefaultOutputDevice: Bool {
        get { hardware.defaultOutputDevice == self }
        set { _ = setDefaultDevice(kAudioHardwarePropertyDefaultOutputDevice) }
    }

    /// Allows getting and setting this device as the default system output device.
    var isDefaultSystemOutputDevice: Bool {
        get { hardware.defaultSystemOutputDevice == self }
        set { _ = setDefaultDevice(kAudioHardwarePropertyDefaultSystemOutputDevice) }
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
