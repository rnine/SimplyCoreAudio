//
//  AudioDevice+Stream.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import AudioToolbox.AudioServices

// MARK: - ♨︎ Stream Functions

public extension AudioDevice {
    /// Returns a list of streams for a given direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* An array of `AudioStream` objects.
    func streams(direction: Direction) -> [AudioStream]? {
        guard let address = validAddress(selector: kAudioDevicePropertyStreams,
                                         scope: scope(direction: direction)) else { return nil }

        var streamIDs = [AudioStreamID]()
        let status = getPropertyDataArray(address, value: &streamIDs, andDefaultValue: 0)

        if noErr != status {
            return nil
        }

        return streamIDs.compactMap { AudioStream.lookup(by: $0) }
    }
}
