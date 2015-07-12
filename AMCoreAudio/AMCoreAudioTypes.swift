//
//  AMCoreAudioTypes.swift
//  AMCoreAudio
//
//  Created by Ruben on 7/7/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation

public enum Direction: String {
    case Invalid
    case Playback
    case Recording
}

public enum TransportType: String {
    case Unknown
    case BuiltIn
    case Aggregate
    case Virtual
    case PCI
    case USB
    case FireWire
    case Bluetooth
    case BluetoothLE
    case HDMI
    case DisplayPort
    case AirPlay
    case AVB
    case Thunderbolt
}

public struct VolumeInfo {
    var volume: Float32?
    var hasVolume: Bool
    var canSetVolume: Bool
    var canMute: Bool
    var isMuted: Bool
    var canPlayThru: Bool
    var isPlayThruSet: Bool

    init() {
        hasVolume = false
        canSetVolume = false
        canMute = false
        isMuted = false
        canPlayThru = false
        isPlayThruSet = false
    }
}
