//
//  Globals.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import CoreAudio.AudioHardwareBase
import Foundation
import os.log

private class BundleFinder {}

extension OSLog {
    private static var subsystem = Bundle(for: BundleFinder.self).bundleIdentifier!

    /// Default logger.
    static let `default` = OSLog(subsystem: subsystem, category: "AMCoreAudio")
}

func scope(direction: Direction) -> AudioObjectPropertyScope {
    return direction == .playback ? kAudioObjectPropertyScopeOutput : kAudioObjectPropertyScopeInput
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
