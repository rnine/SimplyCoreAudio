//
//  AudioStreamEvent.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 20/09/2019.
//  Copyright © 2019 9Labs. All rights reserved.
//

import Foundation

/// Represents an `AudioStream` event.
public enum AudioStreamEvent: Event {
    /// Called whenever the audio stream `isActive` flag changes state.
    case isActiveDidChange(audioStream: AudioStream)

    /// Called whenever the audio stream physical format changes.
    case physicalFormatDidChange(audioStream: AudioStream)
}
