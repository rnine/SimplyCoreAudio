//
//  AudioDevice+Samplerate.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import Foundation
import os.log

// MARK: - 〰 Sample Rate Functions

public extension AudioDevice {
    /// The actual audio device's sample rate.
    ///
    /// - Returns: *(optional)* A `Float64` value with the actual sample rate.
    var actualSampleRate: Float64? {
        guard let address = validAddress(selector: kAudioDevicePropertyActualSampleRate) else { return nil }
        return getProperty(address: address)
    }

    /// The nominal audio device's sample rate.
    ///
    /// - Returns: *(optional)* A `Float64` value with the nominal sample rate.
    var nominalSampleRate: Float64? {
        guard let address = validAddress(selector: kAudioDevicePropertyNominalSampleRate) else { return nil }
        return getProperty(address: address)
    }

    /// A list of all the nominal sample rates supported by this audio device.
    ///
    /// - Returns: *(optional)* A `Float64` array containing the nominal sample rates.
    var nominalSampleRates: [Float64]? {
        guard let address = validAddress(selector: kAudioDevicePropertyAvailableNominalSampleRates,
                                         scope: kAudioObjectPropertyScopeWildcard) else { return nil }

        var sampleRates = [Float64]()
        var valueRanges = [AudioValueRange]()
        let status = getPropertyDataArray(address, value: &valueRanges, andDefaultValue: AudioValueRange())

        guard noErr == status else { return nil }

        // A list of all the possible sample rates up to 192kHz
        // to be used in the case we receive a range (see below)
        let possibleRates: [Float64] = [
            6400, 8000, 11025, 12000,
            16000, 22050, 24000, 32000,
            44100, 48000, 64000, 88200,
            96000, 128_000, 176_400, 192_000
        ]

        for valueRange in valueRanges {
            if valueRange.mMinimum < valueRange.mMaximum {
                // We got a range.
                //
                // This could be a headset audio device (i.e., CS50/CS60-USB Headset)
                // or a virtual audio driver (i.e., "System Audio Recorder" by WonderShare AllMyMusic)
                if let startIndex = possibleRates.firstIndex(of: valueRange.mMinimum),
                   let endIndex = possibleRates.firstIndex(of: valueRange.mMaximum)
                {
                    sampleRates += possibleRates[startIndex..<endIndex + 1]
                } else {
                    os_log("Failed to obtain list of supported sample rates ranging from %f to %f. This is an error in SimplyCoreAudio and should be reported to the project maintainers.", log: .default, type: .debug, valueRange.mMinimum, valueRange.mMaximum)
                }
            } else {
                // We did not get a range (this should be the most common case)
                sampleRates.append(valueRange.mMinimum)
            }
        }

        return sampleRates
    }

    /// Sets the nominal sample rate.
    ///
    /// - Parameter sampleRate: The new nominal sample rate.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setNominalSampleRate(_ sampleRate: Float64) -> Bool {
        guard let address = validAddress(selector: kAudioDevicePropertyNominalSampleRate) else { return false }
        return setProperty(address: address, value: sampleRate)
    }
}
