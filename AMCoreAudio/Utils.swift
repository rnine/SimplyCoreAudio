//
//  Utils.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Foundation

internal func log(_ string: String) {
    print("[AMCoreAudio] \(string)")
}

internal func scope(direction: Direction) -> AudioObjectPropertyScope {
    return .Playback == direction ? kAudioObjectPropertyScopeOutput : kAudioObjectPropertyScopeInput
}

internal func direction(scope: AudioObjectPropertyScope) -> Direction {
    switch scope {
    case kAudioObjectPropertyScopeOutput:
        return .Playback
    case kAudioObjectPropertyScopeInput:
        return .Recording
    default:
        return .Invalid
    }
}
