//
//  Utils.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Foundation

final internal class Utils {
    private init() {}
    
    class func directionToScope(_ direction: Direction) -> AudioObjectPropertyScope {
        return .Playback == direction ? kAudioObjectPropertyScopeOutput : kAudioObjectPropertyScopeInput
    }

    class func scopeToDirection(_ scope: AudioObjectPropertyScope) -> Direction {
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
