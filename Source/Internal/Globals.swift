//
//  Globals.swift
//
//  Created by Ruben Nine on 13/04/16.
//

import CoreAudio.AudioHardwareBase
import Foundation
import os.log

extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier!

    /// Default logger.
    static let `default` = OSLog(subsystem: subsystem, category: "default")
}

func scope(direction: Direction) -> AudioObjectPropertyScope {
    direction == .playback ? kAudioObjectPropertyScopeOutput : kAudioObjectPropertyScopeInput
}

func direction(to scope: AudioObjectPropertyScope) -> Direction? {
    switch scope {
    case kAudioObjectPropertyScopeOutput:
        return .playback
    case kAudioObjectPropertyScopeInput:
        return .recording
    default:
        return nil
    }
}
