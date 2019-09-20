//
//  AudioHardwareEvent.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 20/09/2019.
//  Copyright © 2019 9Labs. All rights reserved.
//

import Foundation

/// Represents an `AudioHardware` event.
public enum AudioHardwareEvent: Event {
    /// Called whenever the list of hardware devices and device subdevices changes.
    /// (i.e., devices that are part of *Aggregate* or *Multi-Output* devices.)
    case deviceListChanged(addedDevices: [AudioDevice], removedDevices: [AudioDevice])

    /// Called whenever the default input device changes.
    case defaultInputDeviceChanged(audioDevice: AudioDevice)

    /// Called whenever the default output device changes.
    case defaultOutputDeviceChanged(audioDevice: AudioDevice)

    /// Called whenever the default system output device changes.
    case defaultSystemOutputDeviceChanged(audioDevice: AudioDevice)
}
