//
//  AudioDevice+Latency.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import Foundation
import os.log

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

    /// A common array of UIInt32 values representing the available
    /// IO buffer size options for the AudioStream containing the given element.
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: An array of common buffer sizes within the defined range
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

public extension AudioDevice {
    /// The latency for a stream on a device is determined by the **sum** of the following properties:
    ///
    /// * kAudioDevicePropertySafetyOffset
    /// * kAudioStreamPropertyLatency
    /// * kAudioDevicePropertyLatency
    /// * kAudioDevicePropertyBufferFrameSize
    struct FixedLatency {
        public internal(set) var stream: UInt32 = 0
        public internal(set) var device: UInt32 = 0
        public internal(set) var safetyOffset: UInt32 = 0
        public internal(set) var bufferFrameSize: UInt32 = 0

        public var totalFrames: UInt32 {
            stream + device + safetyOffset + bufferFrameSize
        }
    }

    /// Calculates the fixed latency from the system and the device
    ///
    /// - Parameter scope: A scope.
    /// - Returns: A `FixedLatency` struct with the latencies in the device.
    /// For the total samples of latency use the `totalFrames` property
    func fixedLatency(scope: Scope) -> FixedLatency {
        var object = FixedLatency()

        if let allStreams = streams(scope: scope) {
            // sum all of them or just take the first stream?
            // it only ever seems to return 1 stream
            let frames = allStreams.compactMap { $0.latency }
            object.stream = frames.reduce(0, +)
        }

        if let frames = latency(scope: scope) {
            object.device = frames
        }

        if let frames = safetyOffset(scope: scope) {
            object.safetyOffset = frames
        }

        if let frames = bufferFrameSize(scope: scope) {
            object.bufferFrameSize = frames
        }

        return object
    }

    /// [PresentationLatency]:
    /// https://developer.apple.com/documentation/avfaudio/avaudioionode/1385631-presentationlatency "PresentationLatency"
    ///
    /// Convenience function to return the total device latency in seconds.
    ///
    /// See: [PresentationLatency]
    ///
    ///  - Parameter scope: A scope.
    /// - Returns: The total summed latency in seconds based on the device's
    /// current sample rate
    func presentationLatency(scope: Scope) -> TimeInterval? {
        guard let sampleRate = actualSampleRate else {
            OSLog.error("Unable to get actualSampleRate from device")
            return nil
        }

        let object = fixedLatency(scope: scope)
        return TimeInterval(object.totalFrames) / sampleRate
    }
}
