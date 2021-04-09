//
//  Notification.Name+Extensions.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import Foundation

/// List of supported `SimplyCoreAudio` notifications.
public extension Notification.Name {
    // MARK: - Audio Hardware Notifications

    /// Called whenever the default input device changes.
    static let defaultInputDeviceChanged = Self("defaultInputDeviceChanged")

    /// Called whenever the default output device changes.
    static let defaultOutputDeviceChanged = Self("defaultOutputDeviceChanged")

    /// Called whenever the default system output device changes.
    static let defaultSystemOutputDeviceChanged = Self("defaultSystemOutputDeviceChanged")

    /// Called whenever the list of hardware devices and device subdevices changes.
    /// (i.e., devices that are part of *Aggregate* or *Multi-Output* devices.)
    ///
    /// Returned `userInfo` object will contain the keys `addedDevices` and `removedDevices`.
    static let deviceListChanged = Self("deviceListChanged")

    // MARK: - Audio Device Notifications

    /// Called whenever the audio device's sample rate changes.
    static let deviceNominalSampleRateDidChange = Self("deviceNominalSampleRateDidChange")

    /// Called whenever the audio device's list of nominal sample rates changes.
    ///
    /// - Note: This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other
    /// audio devices (either physical or virtual.)
    static let deviceAvailableNominalSampleRatesDidChange = Self("deviceAvailableNominalSampleRatesDidChange")

    /// Called whenever the audio device's clock source changes.
    static let deviceClockSourceDidChange = Self("deviceClockSourceDidChange")

    /// Called whenever the audio device's name changes.
    static let deviceNameDidChange = Self("deviceNameDidChange")

    /// Called whenever the list of owned audio devices on this audio device changes.
    ///
    /// - Note: This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other
    /// audio devices (either physical or virtual.)
    static let deviceOwnedObjectsDidChange = Self("deviceOwnedObjectsDidChange")

    /// Called whenever the audio device's volume for a given channel and scope changes.
    ///
    /// Returned `userInfo` object will contain the keys `channel` and `scope`.
    static let deviceVolumeDidChange = Self("deviceVolumeDidChange")

    /// Called whenever the audio device's mute state for a given channel and scope changes.
    ///
    /// Returned `userInfo` object will contain the keys `channel` and `scope`.
    static let deviceMuteDidChange = Self("deviceMuteDidChange")

    /// Called whenever the audio device's *is alive* property changes.
    static let deviceIsAliveDidChange = Self("deviceIsAliveDidChange")

    /// Called whenever the audio device's *is running* property changes.
    static let deviceIsRunningDidChange = Self("deviceIsRunningDidChange")

    /// Called whenever the audio device's *is running somewhere* property changes.
    static let deviceIsRunningSomewhereDidChange = Self("deviceIsRunningSomewhereDidChange")

    /// Called whenever the audio device's *is jack connected* property changes.
    static let deviceIsJackConnectedDidChange = Self("deviceIsJackConnectedDidChange")

    /// Called whenever the audio device's *preferred channels for stereo* property changes.
    static let devicePreferredChannelsForStereoDidChange = Self("devicePreferredChannelsForStereoDidChange")

    /// Called whenever the audio device's *hog mode* property changes.
    static let deviceHogModeDidChange = Self("deviceHogModeDidChange")

    /// Called when the AudioDevice detects that an IO cycle has
    /// run past its deadline. Note that the notification for this property is
    /// usually sent from the AudioDevice's IO thread.
    static let deviceProcessorOverload = Self("deviceProcessorOverload")

    /// Called when IO on the device has stopped outside of the
    /// normal mechanisms. This typically comes up when IO is stopped after
    /// AudioDeviceStart has returned successfully but prior to the notification for
    /// kAudioDevicePropertyIsRunning being sent.
    static let deviceIOStoppedAbnormally = Self("deviceIOStoppedAbnormally")

    // MARK: - Audio Stream Notifications

    /// Called whenever the audio stream `isActive` flag changes.
    static let streamIsActiveDidChange = Self("streamIsActiveDidChange")

    /// Called whenever the audio stream physical format changes.
    static let streamPhysicalFormatDidChange = Self("streamPhysicalFormatDidChange")
}

private extension Notification.Name {
    init(_ name: String) {
        self.init(rawValue: "SimplyCoreAudio.\(name)")
    }
}
