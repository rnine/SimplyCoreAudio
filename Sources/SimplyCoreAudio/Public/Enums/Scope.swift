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
    /// The AudioObjectPropertyScope for properties that apply to the object as a
    /// whole. All objects have a global scope and for most it is their only scope.
    case global

    /// The AudioObjectPropertyScope for properties that apply to the input side of
    /// an object
    case input

    /// The AudioObjectPropertyScope for properties that apply to the output side of
    /// an object.
    case output

    /// The AudioObjectPropertyScope for properties that apply to the play through
    /// side of an object.
    case playthrough

    /// The AudioObjectPropertyElement value for properties that apply to the main
    /// element or to the entire scope. Using deprecated naming
    case master

    /// The wildcard value for AudioObjectPropertySelectors
    case wildcard
    
    /// The AudioObjectPropertyElement value for properties that apply to the main
    /// element or to the entire scope.
    case main
}

// MARK: - Internal Functions

extension Scope {
    var asPropertyScope: AudioObjectPropertyScope {
        switch self {
        case .global: return kAudioObjectPropertyScopeGlobal
        case .input: return kAudioObjectPropertyScopeInput
        case .output: return kAudioObjectPropertyScopeOutput
        case .playthrough: return kAudioObjectPropertyScopePlayThrough
        case .main, .master: return Element.main.asPropertyElement
        case .wildcard: return kAudioObjectPropertyScopeWildcard
        }
    }

    static func from(_ scope: AudioObjectPropertyScope) -> Scope {
        switch scope {
        case kAudioObjectPropertyScopeGlobal: return .global
        case kAudioObjectPropertyScopeInput: return .input
        case kAudioObjectPropertyScopeOutput: return .output
        case kAudioObjectPropertyScopePlayThrough: return .playthrough
        case kAudioObjectPropertyElementMaster: return .master
        case Element.main.asPropertyElement: return .main
        case kAudioObjectPropertyScopeWildcard: return .wildcard
        default:
            // Note, the default is only here to satisfy the switch to be exhaustive.
            // It already defines the complete set of AudioObjectPropertyScope from
            // AudioHardware.h, so it's pretty unlikely this would be returned. The
            // only case should be if Apple adds a new scope type - which seems fairly
            // unlikely
            return .wildcard
        }
    }
}
