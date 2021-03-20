//
//  Notifications.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import Foundation

enum Notifications: String, NotificationName {
    /// Called whenever the audio device's sample rate changes.
    case deviceNominalSampleRateDidChange

    /// Called whenever the audio device's list of nominal sample rates changes.
    ///
    /// - Note: This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other
    /// audio devices (either physical or virtual.)
    case deviceAvailableNominalSampleRatesDidChange

    /// Called whenever the audio device's clock source changes.
    case deviceClockSourceDidChange

    /// Called whenever the audio device's name changes.
    case deviceNameDidChange

    /// Called whenever the list of owned audio devices on this audio device changes.
    ///
    /// - Note: This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other
    /// audio devices (either physical or virtual.)
    case deviceOwnedObjectsDidChange

    /// Called whenever the audio device's volume for a given channel and direction changes.
    ///
    /// Returned `userInfo` object will contain the keys `channel` and `direction`.
    case deviceVolumeDidChange

    /// Called whenever the audio device's mute state for a given channel and direction changes.
    ///
    /// Returned `userInfo` object will contain the keys `channel` and `direction`.
    case deviceMuteDidChange

    /// Called whenever the audio device's *is alive* property changes.
    case deviceIsAliveDidChange

    /// Called whenever the audio device's *is running* property changes.
    case deviceIsRunningDidChange

    /// Called whenever the audio device's *is running somewhere* property changes.
    case deviceIsRunningSomewhereDidChange

    /// Called whenever the audio device's *is jack connected* property changes.
    case deviceIsJackConnectedDidChange

    /// Called whenever the audio device's *preferred channels for stereo* property changes.
    case devicePreferredChannelsForStereoDidChange

    /// Called whenever the audio device's *hog mode* property changes.
    case deviceHogModeDidChange

    /// Called whenever the list of hardware devices and device subdevices changes.
    /// (i.e., devices that are part of *Aggregate* or *Multi-Output* devices.)
    ///
    /// Returned `userInfo` object will contain the keys `addedDevices` and `removedDevices`.
    case deviceListChanged

    /// Called whenever the default input device changes.
    case defaultInputDeviceChanged

    /// Called whenever the default output device changes.
    case defaultOutputDeviceChanged

    /// Called whenever the default system output device changes.
    case defaultSystemOutputDeviceChanged

    /// Called whenever the audio stream `isActive` flag changes state.
    case streamIsActiveDidChange

    /// Called whenever the audio stream physical format changes.
    case streamPhysicalFormatDidChange
}
