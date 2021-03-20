//
//  AudioDevice+Channel.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import AudioToolbox.AudioServices

// MARK: - ⇉ Individual Channel Functions

public extension AudioDevice {
    /// A `VolumeInfo` struct containing information about a particular channel and direction combination.
    ///
    /// - Parameter channel: A channel.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `VolumeInfo` struct.
    func volumeInfo(channel: UInt32, direction: Direction) -> VolumeInfo? {
        // Obtain volume info
        var address: AudioObjectPropertyAddress
        var hasAnyProperty = false

        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope(direction: direction),
            mElement: channel
        )

        var volumeInfo = VolumeInfo()

        if AudioObjectHasProperty(id, &address) {
            var canSetVolumeBoolean = DarwinBoolean(false)
            var status = AudioObjectIsPropertySettable(id, &address, &canSetVolumeBoolean)

            if noErr == status {
                volumeInfo.canSetVolume = canSetVolumeBoolean.boolValue
                volumeInfo.hasVolume = true

                var volume = Float32(0)
                status = getPropertyData(address, andValue: &volume)

                if noErr == status {
                    volumeInfo.volume = volume
                    hasAnyProperty = true
                }
            }
        }

        // Obtain mute info
        address.mSelector = kAudioDevicePropertyMute

        if AudioObjectHasProperty(id, &address) {
            var canMuteBoolean = DarwinBoolean(false)
            var status = AudioObjectIsPropertySettable(id, &address, &canMuteBoolean)

            if noErr == status {
                volumeInfo.canMute = canMuteBoolean.boolValue

                var isMutedValue = UInt32(0)
                status = getPropertyData(address, andValue: &isMutedValue)

                if noErr == status {
                    volumeInfo.isMuted = Bool(isMutedValue)
                    hasAnyProperty = true
                }
            }
        }

        // Obtain play thru info
        address.mSelector = kAudioDevicePropertyPlayThru

        if AudioObjectHasProperty(id, &address) {
            var canPlayThruBoolean = DarwinBoolean(false)
            var status = AudioObjectIsPropertySettable(id, &address, &canPlayThruBoolean)

            if noErr == status {
                volumeInfo.canPlayThru = canPlayThruBoolean.boolValue

                var isPlayThruSetValue = UInt32(0)
                status = getPropertyData(address, andValue: &isPlayThruSetValue)

                if noErr == status {
                    volumeInfo.isPlayThruSet = Bool(isPlayThruSetValue)
                    hasAnyProperty = true
                }
            }
        }

        return hasAnyProperty ? volumeInfo : nil
    }

    /// The scalar volume for a given channel and direction.
    ///
    /// - Parameter channel: A channel.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `Float32` value with the scalar volume.
    func volume(channel: UInt32, direction: Direction) -> Float32? {
        guard let address = validAddress(selector: kAudioDevicePropertyVolumeScalar,
                                         scope: scope(direction: direction),
                                         element: channel) else { return nil }

        return getProperty(address: address)
    }

    /// The volume in decibels *(dbFS)* for a given channel and direction.
    ///
    /// - Parameter channel: A channel.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `Float32` value with the volume in decibels.
    func volumeInDecibels(channel: UInt32, direction: Direction) -> Float32? {
        guard let address = validAddress(selector: kAudioDevicePropertyVolumeDecibels,
                                         scope: scope(direction: direction),
                                         element: channel) else { return nil }

        return getProperty(address: address)
    }

    /// Sets the channel's volume for a given direction.
    ///
    /// - Parameter volume: The new volume as a scalar value ranging from 0 to 1.
    /// - Parameter channel: A channel.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setVolume(_ volume: Float32, channel: UInt32, direction: Direction) -> Bool {
        guard let address = validAddress(selector: kAudioDevicePropertyVolumeScalar,
                                         scope: scope(direction: direction),
                                         element: channel) else { return false }

        return setProperty(address: address, value: volume)
    }

    /// Mutes a channel for a given direction.
    ///
    /// - Parameter shouldMute: Whether channel should be muted or not.
    /// - Parameter channel: A channel.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setMute(_ shouldMute: Bool, channel: UInt32, direction: Direction) -> Bool {
        guard let address = validAddress(selector: kAudioDevicePropertyMute,
                                         scope: scope(direction: direction),
                                         element: channel) else { return false }

        return setProperty(address: address, value: shouldMute)
    }

    /// Whether a channel is muted for a given direction.
    ///
    /// - Parameter channel: A channel.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* `true` if channel is muted, false otherwise.
    func isMuted(channel: UInt32, direction: Direction) -> Bool? {
        guard let address = validAddress(selector: kAudioDevicePropertyMute,
                                         scope: scope(direction: direction),
                                         element: channel) else { return nil }

        return getProperty(address: address)
    }

    /// Whether the master channel is muted for a given direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` when muted, `false` otherwise.
    func isMasterChannelMuted(direction: Direction) -> Bool? {
        isMuted(channel: kAudioObjectPropertyElementMaster, direction: direction)
    }

    /// Whether a channel can be muted for a given direction.
    ///
    /// - Parameter channel: A channel.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` if channel can be muted, `false` otherwise.
    func canMute(channel: UInt32, direction: Direction) -> Bool {
        volumeInfo(channel: channel, direction: direction)?.canMute ?? false
    }

    /// Whether the master volume can be muted for a given direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` when the volume can be muted, `false` otherwise.
    func canMuteMasterChannel(direction: Direction) -> Bool {
        if canMute(channel: kAudioObjectPropertyElementMaster, direction: direction) == true {
            return true
        }

        guard let preferredChannelsForStereo = preferredChannelsForStereo(direction: direction) else { return false }
        guard canMute(channel: preferredChannelsForStereo.0, direction: direction) else { return false }
        guard canMute(channel: preferredChannelsForStereo.1, direction: direction) else { return false }

        return true
    }

    /// Whether a channel's volume can be set for a given direction.
    ///
    /// - Parameter channel: A channel.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` if the channel's volume can be set, `false` otherwise.
    func canSetVolume(channel: UInt32, direction: Direction) -> Bool {
        volumeInfo(channel: channel, direction: direction)?.canSetVolume ?? false
    }

    /// A list of channel numbers that best represent the preferred stereo channels
    /// used by this device. In most occasions this will be channels 1 and 2.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: A `StereoPair` tuple containing the channel numbers.
    func preferredChannelsForStereo(direction: Direction) -> StereoPair? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: scope(direction: direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var preferredChannels = [UInt32]()
        let status = getPropertyDataArray(address, value: &preferredChannels, andDefaultValue: 0)

        guard noErr == status, preferredChannels.count == 2 else { return nil }

        return (left: preferredChannels[0], right: preferredChannels[1])
    }

    /// Attempts to set the new preferred channels for stereo for a given direction.
    ///
    /// - Parameter channels: A `StereoPair` representing the preferred channels.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setPreferredChannelsForStereo(channels: StereoPair, direction: Direction) -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: scope(direction: direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var preferredChannels = [channels.left, channels.right]
        let status = setPropertyData(address, andValue: &preferredChannels)

        return noErr == status
    }
}
