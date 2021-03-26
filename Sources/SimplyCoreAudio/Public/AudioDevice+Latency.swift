//
//  AudioDevice+Latency.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import Foundation

// MARK: - ↹ Latency Functions

public extension AudioDevice {
    /// The latency in frames for the specified scope.
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: *(optional)* A `UInt32` value with the latency in frames.
    func latency(scope: Scope) -> UInt32? {
        guard let address = validAddress(selector: kAudioDevicePropertyLatency,
                                         scope: scope.asPropertyScope) else { return nil }

        return getProperty(address: address)
    }

    /// The safety offset frames for the specified scope.
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: *(optional)* A `UInt32` value with the safety offset in frames.
    func safetyOffset(scope: Scope) -> UInt32? {
        guard let address = validAddress(selector: kAudioDevicePropertySafetyOffset,
                                         scope: scope.asPropertyScope) else { return nil }

        return getProperty(address: address)
    }
}
