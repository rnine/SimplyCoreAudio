//
//  AMUtils.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Cocoa

final internal class AMUtils: NSObject {

    class func directionToScope(direction: Direction) -> AudioObjectPropertyScope {
        return .Playback == direction ? kAudioObjectPropertyScopeOutput : kAudioObjectPropertyScopeInput
    }

    class func scopeToDirection(scope: AudioObjectPropertyScope) -> Direction {
        switch scope {
        case kAudioObjectPropertyScopeOutput:
            return .Playback
        case kAudioObjectPropertyScopeInput:
            return .Recording
        default:
            return .Invalid
        }
    }

}
