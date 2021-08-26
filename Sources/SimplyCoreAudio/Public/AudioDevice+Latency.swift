// Copyright SimplyCoreAudio. All Rights Reserved. Revision History at https://github.com/rnine/SimplyCoreAudio

import CoreAudio
import Foundation
import os.log

// MARK: - ↹ Latency Functions

public extension AudioDevice {
    /// Convenience function to return the total latency in frames of an AudioDevice
    ///
    /// The latency for a scope is determined by the **sum** of the following properties:
    ///
    /// * kAudioDevicePropertySafetyOffset
    /// * kAudioStreamPropertyLatency
    /// * kAudioDevicePropertyLatency
    /// * kAudioDevicePropertyBufferFrameSize
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: A `UInt32` value with the total frames of latency in the device.
    ///
    func latency(scope: Scope) -> UInt32 {
        var sum: UInt32 = 0

        if let allStreams = streams(scope: scope) {
            // sum all of them or just take the first stream?
            // it only ever seems to return 1 stream
            let frames = allStreams.compactMap { $0.latency }
            sum = frames.reduce(0, +)
        }

        if let frames = deviceLatency(scope: scope) {
            sum += frames
        }

        if let frames = safetyOffset(scope: scope) {
            sum += frames
        }

        if let frames = bufferFrameSize(scope: scope) {
            sum += frames
        }

        return sum
    }

    /// [PresentationLatency]:
    /// https://developer.apple.com/documentation/avfaudio/avaudioionode/1385631-presentationlatency "PresentationLatency"
    ///
    /// Convenience function to return the total latency in seconds.
    ///
    /// See: [PresentationLatency]
    ///
    ///  - Parameter scope: A scope.
    ///
    /// - Returns: *(optional)* The total summed latency in seconds based on the device's
    /// current sample rate or nil if the sample rate wasn't determined.
    func presentationLatency(scope: Scope) -> TimeInterval? {
        guard let sampleRate = actualSampleRate else {
            os_log("Unable to get actualSampleRate from device")
            return nil
        }

        let totalFrames = latency(scope: scope)
        return TimeInterval(totalFrames) / sampleRate
    }
}

public extension AudioDevice {
    /// The latency in frames for the specified scope.
    /// Corresponds to the CoreAudio `kAudioDevicePropertyLatency` property
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: *(optional)* A `UInt32` value with the latency in frames.
    func deviceLatency(scope: Scope) -> UInt32? {
        guard let address = validAddress(selector: kAudioDevicePropertyLatency,
                                         scope: scope.asPropertyScope) else { return nil }

        return getProperty(address: address)
    }

    /// The safety offset frames for the specified scope.
    ///
    /// Corresponds to the CoreAudio `kAudioDevicePropertySafetyOffset` property
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
    /// Corresponds to the CoreAudio `kAudioDevicePropertyBufferFrameSize` property
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

        // limit it to these common sizes
        let possibleBufferSizes: [UInt32] = [16, 32, 64, 128, 256,
                                             512, 1024, 2048, 4096]

        guard let lowerBound = possibleBufferSizes.first,
              let upperBound = possibleBufferSizes.last else { return nil }

        let startValue = UInt32(firstRange.mMinimum + 15) & ~15
        if !bufferSizes.contains(startValue) {
            bufferSizes.append(startValue)
        }

        var size: UInt32 = startValue <= lowerBound ? startValue : lowerBound

        while size <= upperBound {
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
