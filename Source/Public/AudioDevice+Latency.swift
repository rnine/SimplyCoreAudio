//
//  AudioDevice+Latency.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import AudioToolbox.AudioServices

// MARK: - ↹ Latency Functions

public extension AudioDevice {
    /// The latency in frames for the specified direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `UInt32` value with the latency in frames.
    func latency(direction: Direction) -> UInt32? {
        guard let address = validAddress(selector: kAudioDevicePropertyLatency,
                                         scope: scope(direction: direction)) else { return nil }

        return getProperty(address: address)
    }

    /// The safety offset frames for the specified direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `UInt32` value with the safety offset in frames.
    func safetyOffset(direction: Direction) -> UInt32? {
        guard let address = validAddress(selector: kAudioDevicePropertySafetyOffset,
                                         scope: scope(direction: direction)) else { return nil }

        return getProperty(address: address)
    }
}
