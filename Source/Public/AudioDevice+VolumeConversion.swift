//
//  AudioDevice+VolumeConversion.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import AudioToolbox.AudioServices

// MARK: - ♺ Volume Conversion Functions

public extension AudioDevice {
    /// Converts a scalar volume to a decibel *(dbFS)* volume for the given channel and direction.
    ///
    /// - Parameter volume: A scalar volume.
    /// - Parameter channel: A channel number.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `Float32` value with the scalar volume converted in decibels.
    func scalarToDecibels(volume: Float32, channel: UInt32, direction: Direction) -> Float32? {
        guard let address = validAddress(selector: kAudioDevicePropertyVolumeScalarToDecibels,
                                         scope: scope(direction: direction),
                                         element: channel) else { return nil }

        var inOutVolume = volume
        let status = getPropertyData(address, andValue: &inOutVolume)

        return noErr == status ? inOutVolume : nil
    }

    /// Converts a relative decibel *(dbFS)* volume to a scalar volume for the given channel and direction.
    ///
    /// - Parameter volume: A volume in relative decibels (dbFS).
    /// - Parameter channel: A channel number.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `Float32` value with the decibels volume converted to scalar.
    func decibelsToScalar(volume: Float32, channel: UInt32, direction: Direction) -> Float32? {
        guard let address = validAddress(selector: kAudioDevicePropertyVolumeDecibelsToScalar,
                                         scope: scope(direction: direction),
                                         element: channel) else { return nil }

        var inOutVolume = volume
        let status = getPropertyData(address, andValue: &inOutVolume)

        return noErr == status ? inOutVolume : nil
    }
}
