//
//  AudioDevice+IOLayout.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import AudioToolbox.AudioServices

// MARK: - ⇄ Input/Output Layout Functions

public extension AudioDevice {
    /// Whether the device has only inputs but no outputs.
    ///
    /// - Returns: `true` when the device is input only, `false` otherwise.
    var isInputOnlyDevice: Bool {
        return channels(direction: .playback) == 0 && channels(direction: .recording) > 0
    }

    /// Whether the device has only outputs but no inputs.
    ///
    /// - Returns: `true` when the device is output only, `false` otherwise.
    var isOutputOnlyDevice: Bool {
        return channels(direction: .recording) == 0 && channels(direction: .playback) > 0
    }

    /// The number of layout channels for a given direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `UInt32` with the number of layout channels.
    func layoutChannels(direction: Direction) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelLayout,
            mScope: scope(direction: direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        if AudioObjectHasProperty(id, &address) {
            var result = AudioChannelLayout()
            let status = getPropertyData(address, andValue: &result)

            return noErr == status ? result.mNumberChannelDescriptions : nil
        }

        return nil
    }

    /// The number of channels for a given direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: A `UInt32` with the number of channels.
    func channels(direction: Direction) -> UInt32 {
        guard let streams = streams(direction: direction) else { return 0 }

        return streams.map { $0.physicalFormat?.mChannelsPerFrame ?? 0 }.reduce(0, +)
    }

    /// A human readable name for the channel number and direction specified.
    ///
    /// - Parameter channel: A channel.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `String` with the name of the channel.
    func name(channel: UInt32, direction: Direction) -> String? {
        guard let address = validAddress(selector: kAudioObjectPropertyElementName,
                                         scope: scope(direction: direction),
                                         element: channel) else { return nil }

        guard let name: String = getProperty(address: address) else { return nil }

        return name.isEmpty ? nil : name
    }

    /// Whether the audio device's jack is connected for a given direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` when jack is connected, `false` otherwise.
    func isJackConnected(direction: Direction) -> Bool? {
        if let address = validAddress(selector: kAudioDevicePropertyJackIsConnected,
                                      scope: scope(direction: direction))
        {
            return getProperty(address: address)
        } else {
            return nil
        }
    }
}
