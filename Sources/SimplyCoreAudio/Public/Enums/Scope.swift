//
//  Scope.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import CoreAudio
import Foundation

/// Indicates the scope used by an `AudioDevice` or `AudioStream`.
///
/// Please notice that `AudioStream` only supports `input` and `output` scopes,
/// whether as `AudioDevice` may, additionally, support `global` and `playthrough`.
public enum Scope {
    /// Global scope
    case global
    /// Input scope
    case input
    /// Output scope
    case output
    /// Playthrough scope
    case playthrough
}

// MARK: - Internal Functions

extension Scope {
    var asPropertyScope: AudioObjectPropertyScope {
        switch self {
        case .global: return kAudioObjectPropertyScopeGlobal
        case .input: return kAudioObjectPropertyScopeInput
        case .output: return kAudioObjectPropertyScopeOutput
        case .playthrough: return kAudioObjectPropertyScopePlayThrough
        }
    }

    static func from(_ scope: AudioObjectPropertyScope) -> Scope? {
        switch scope {
        case kAudioObjectPropertyScopeGlobal: return .global
        case kAudioObjectPropertyScopeInput: return .input
        case kAudioObjectPropertyScopeOutput: return .output
        case kAudioObjectPropertyScopePlayThrough: return .playthrough
        default: return nil
        }
    }
}
