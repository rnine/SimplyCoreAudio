//
//  AudioDeviceEvent.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 20/09/2019.
//  Copyright © 2019 9Labs. All rights reserved.
//

import Foundation

/// Represents an `AudioDevice` event.
public enum AudioDeviceEvent: Event {
    /// Called whenever the audio device's sample rate changes.
    case nominalSampleRateDidChange(audioDevice: AudioDevice)

    /// Called whenever the audio device's list of nominal sample rates changes.
    ///
    /// - Note: This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other
    /// audio devices (either physical or virtual.)
    case availableNominalSampleRatesDidChange(audioDevice: AudioDevice)

    /// Called whenever the audio device's clock source changes.
    case clockSourceDidChange(audioDevice: AudioDevice)

    /// Called whenever the audio device's name changes.
    case nameDidChange(audioDevice: AudioDevice)

    /// Called whenever the list of owned audio devices on this audio device changes.
    ///
    /// - Note: This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other
    /// audio devices (either physical or virtual.)
    case listDidChange(audioDevice: AudioDevice)

    /// Called whenever the audio device's volume for a given channel and direction changes.
    case volumeDidChange(audioDevice: AudioDevice, channel: UInt32, direction: Direction)

    /// Called whenever the audio device's mute state for a given channel and direction changes.
    case muteDidChange(audioDevice: AudioDevice, channel: UInt32, direction: Direction)

    /// Called whenever the audio device's *is alive* property changes.
    case isAliveDidChange(audioDevice: AudioDevice)

    /// Called whenever the audio device's *is running* property changes.
    case isRunningDidChange(audioDevice: AudioDevice)

    /// Called whenever the audio device's *is running somewhere* property changes.
    case isRunningSomewhereDidChange(audioDevice: AudioDevice)

    /// Called whenever the audio device's *is jack connected* property changes.
    case isJackConnectedDidChange(audioDevice: AudioDevice)

    /// Called whenever the audio device's *preferred channels for stereo* property changes.
    case preferredChannelsForStereoDidChange(audioDevice: AudioDevice)

    /// Called whenever the audio device's *hog mode* property changes.
    case hogModeDidChange(audioDevice: AudioDevice)
}
