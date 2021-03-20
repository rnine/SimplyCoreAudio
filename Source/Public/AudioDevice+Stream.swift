//
//  AudioDevice+Stream.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import AudioToolbox.AudioServices

// MARK: - ♨︎ Stream Functions

public extension AudioDevice {
    /// Returns a list of streams for a given scope.
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: *(optional)* An array of `AudioStream` objects.
    func streams(scope: Scope) -> [AudioStream]? {
        guard let address = validAddress(selector: kAudioDevicePropertyStreams,
                                         scope: propertyScope(from: scope)) else { return nil }

        var streamIDs = [AudioStreamID]()
        let status = getPropertyDataArray(address, value: &streamIDs, andDefaultValue: 0)

        if noErr != status {
            return nil
        }

        return streamIDs.compactMap { AudioStream.lookup(by: $0) }
    }
}
