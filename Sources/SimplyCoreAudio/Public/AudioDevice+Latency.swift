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

    @discardableResult
    func setBufferFrameSize(_ frameSize: UInt32, scope: Scope) -> Bool {
        guard let address = validAddress(selector: kAudioDevicePropertyBufferFrameSize,
                                         scope: scope.asPropertyScope) else { return false }

        return setProperty(address: address, value: frameSize)
    }
}

public extension AudioDevice {
    /**
     Calculate the fixed latency from the system and the device.

     The latency for a stream on a device is determined by the sum of the following properties:
         kAudioDevicePropertySafetyOffset
         kAudioStreamPropertyLatency
         kAudioDevicePropertyLatency
         kAudioDevicePropertyBufferFrameSize
     */
    struct FixedLatency {
        public internal(set) var streamFrames: UInt32 = 0
        public internal(set) var deviceFrames: UInt32 = 0
        public internal(set) var safeteyOffsetFrames: UInt32 = 0
        public internal(set) var bufferFrameSize: UInt32 = 0

        public var totalFrames: UInt32 {
            streamFrames + deviceFrames + safeteyOffsetFrames + bufferFrameSize
        }
    }

    func fixedLatency(scope: Scope) -> FixedLatency {
        var object = FixedLatency()

        if let allStreams = streams(scope: scope) {
            // sum all of them or just take the first stream?
            let frames = allStreams.compactMap { $0.latency }
            object.streamFrames = frames.reduce(0, +)
        }

        if let frames = latency(scope: scope) {
            object.deviceFrames = frames
        }

        if let frames = safetyOffset(scope: scope) {
            object.safeteyOffsetFrames = frames
        }

        // kAudioDevicePropertyBufferFrameSize
        // kAudioDevicePropertyBufferFrameSizeRange

        if let frames = bufferFrameSize(scope: scope) {
            object.bufferFrameSize = frames // * 2
        }

        return object
    }

    func presentationLatency(scope: Scope) -> TimeInterval? {
        guard let sampleRate = actualSampleRate else { return nil }

        let object = fixedLatency(scope: scope)
        return TimeInterval(object.totalFrames) / sampleRate
    }
}
