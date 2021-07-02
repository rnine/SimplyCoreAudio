//
//  AudioDevice+Latency.swift
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

    /// The current size of the IO Buffer
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: *(optional)* A `UInt32` value that indicates the number of frames in the IO buffers.
    func bufferFrameSize(scope: Scope) -> UInt32? {
        guard let address = validAddress(selector: kAudioDevicePropertyBufferFrameSize,
                                         scope: scope.asPropertyScope) else { return nil }

        return getProperty(address: address)
    }

    /// Set the current size of the IO Buffer
    ///
    /// - Parameter frameSize: A valid buffer size.
    /// - Parameter scope: A scope.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult
    func setBufferFrameSize(_ frameSize: UInt32, scope: Scope) -> Bool {
        guard let address = validAddress(selector: kAudioDevicePropertyBufferFrameSize,
                                         scope: scope.asPropertyScope) else { return false }

        return setProperty(address: address, value: frameSize)
    }

    /// A common array of UInt32 values representing the available
    /// IO buffer size options for the AudioStream containing the given element.
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: An array of common buffer sizes within the defined range such as 32 ... 1024
    func bufferFrameSizeRange(scope: Scope) -> [UInt32]? {
        guard let address = validAddress(selector: kAudioDevicePropertyBufferFrameSizeRange,
                                         scope: kAudioObjectPropertyScopeWildcard) else { return nil }

        var bufferSizes = [UInt32]()
        var ranges = [AudioValueRange]()
        let status = getPropertyDataArray(address, value: &ranges, andDefaultValue: AudioValueRange())

        guard noErr == status,
              let firstRange = ranges.first else { return nil }

        // limit it to these
        let possibleBufferSizes: [UInt32] = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]

        guard let lowerBound = possibleBufferSizes.first,
              let upperBound = possibleBufferSizes.last else { return nil }

        let startValue = UInt32(firstRange.mMinimum + 15) & ~15
        if !bufferSizes.contains(startValue) {
            bufferSizes.append(startValue)
        }

        var size: UInt32 = startValue <= lowerBound ? startValue : lowerBound

        while size <= upperBound {
            // OSLog.debug(size)

            for range in ranges {
                let min = UInt32(range.mMinimum)
                let max = UInt32(range.mMaximum)

                if size >= min && size <= max &&
                    possibleBufferSizes.contains(size) &&
                    !bufferSizes.contains(size) {
                    bufferSizes.append(size)
                }
            }
            size *= 2
        }

        return bufferSizes.sorted()
    }
}
