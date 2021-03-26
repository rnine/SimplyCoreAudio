//
//  AudioDevice+Stream.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import Foundation

// MARK: - ♨︎ Stream Functions

public extension AudioDevice {
    /// Returns a list of streams for a given scope.
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: *(optional)* An array of `AudioStream` objects.
    func streams(scope: Scope) -> [AudioStream]? {
        guard let address = validAddress(selector: kAudioDevicePropertyStreams,
                                         scope: scope.asPropertyScope) else { return nil }

        var streamIDs = [AudioStreamID]()

        guard noErr == getPropertyDataArray(address, value: &streamIDs, andDefaultValue: 0) else { return nil }

        return streamIDs.compactMap { AudioStream.lookup(by: $0) }
    }
}
