//
//  AudioDevice+LFE.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import Foundation

// MARK: - 💣 LFE (Low Frequency Effects) Functions

public extension AudioDevice {
    /// Whether the audio device should claim ownership of any attached iSub or not.
    ///
    /// - Return: *(optional)* `true` when device should claim ownership, `false` otherwise.
    var shouldOwniSub: Bool? {
        get {
            guard let address = validAddress(selector: kAudioDevicePropertyDriverShouldOwniSub) else { return nil }
            return getProperty(address: address)
        }

        set {
            if let value = newValue, let address = validAddress(selector: kAudioDevicePropertyDriverShouldOwniSub) {
                _ = setProperty(address: address, value: value)
            }
        }
    }

    /// Whether the audio device's LFE (Low Frequency Effects) output is muted or not.
    ///
    /// - Return: *(optional)* `true` when LFE output is muted, `false` otherwise.
    var lfeMute: Bool? {
        get {
            guard let address = validAddress(selector: kAudioDevicePropertySubMute) else { return nil }
            return getProperty(address: address)
        }

        set {
            if let value = newValue, let address = validAddress(selector: kAudioDevicePropertySubMute) {
                _ = setProperty(address: address, value: value)
            }
        }
    }

    /// The audio device's LFE (Low Frequency Effects) scalar output volume.
    ///
    /// - Return: *(optional)* A `Float32` with the volume.
    var lfeVolume: Float32? {
        get {
            guard let address = validAddress(selector: kAudioDevicePropertySubVolumeScalar) else { return nil }
            return getProperty(address: address)
        }

        set {
            if let value = newValue, let address = validAddress(selector: kAudioDevicePropertySubVolumeScalar) {
                _ = setProperty(address: address, value: value)
            }
        }
    }

    /// The audio device's LFE (Low Frequency Effects) output volume in decibels.
    ///
    /// - Return: *(optional)* A `Float32` with the volume.
    var lfeVolumeDecibels: Float32? {
        get {
            guard let address = validAddress(selector: kAudioDevicePropertySubVolumeDecibels) else { return nil }
            return getProperty(address: address)
        }

        set {
            if let value = newValue, let address = validAddress(selector: kAudioDevicePropertySubVolumeDecibels) {
                _ = setProperty(address: address, value: value)
            }
        }
    }
}
