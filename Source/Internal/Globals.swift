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

func propertyScope(from scope: Scope) -> AudioObjectPropertyScope {
    switch scope {
    case .global: return kAudioObjectPropertyScopeGlobal
    case .input: return kAudioObjectPropertyScopeInput
    case .output: return kAudioObjectPropertyScopeOutput
    case .playthrough: return kAudioObjectPropertyScopePlayThrough
    }
}

func scope(from propertyScope: AudioObjectPropertyScope) -> Scope? {
    switch propertyScope {
    case kAudioObjectPropertyScopeGlobal: return .global
    case kAudioObjectPropertyScopeInput: return .input
    case kAudioObjectPropertyScopeOutput: return .output
    case kAudioObjectPropertyScopePlayThrough: return .playthrough
    default: return nil
    }
}
