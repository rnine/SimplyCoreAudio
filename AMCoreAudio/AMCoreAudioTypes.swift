//
//  AMCoreAudioTypes.swift
//  AMCoreAudio
//
//  Created by Ruben on 7/7/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation

/**
    Indicates the direction used by an `AMAudioDevice` or `AMAudioStream`.
 */
public enum Direction: String {
    /**
        Invalid direction
     */
    case Invalid
    /**
        Playback direction
     */
    case Playback
    /**
        Recording direction
     */
    case Recording
}

/**
    Indicates the transport type used by an `AMAudioDevice`.
 */
public enum TransportType: String {
    /**
        Unknown Transport Type
     */
    case Unknown
    /**
        Built-In Transport Type
     */
    case BuiltIn
    /**
        Aggregate Transport Type
     */
    case Aggregate
    /**
        Virtual Transport Type
     */
    case Virtual
    /**
        PCI Transport Type
     */
    case PCI
    /**
        USB Transport Type
     */
    case USB
    /**
        FireWire Transport Type
     */
    case FireWire
    /**
        Bluetooth Transport Type
     */
    case Bluetooth
    /**
        Bluetooth LE Transport Type
     */
    case BluetoothLE
    /**
        HDMI Transport Type
     */
    case HDMI
    /**
        DisplayPort Transport Type
     */
    case DisplayPort
    /**
        AirPlay Transport Type
     */
    case AirPlay
    /**
        Audio Video Bridging (AVB) Transport Type
     */
    case AVB
    /**
        Thunderbolt Transport Type
     */
    case Thunderbolt
}

/**
    This struct holds volume, mute, and playthru information about a given channel and direction of an `AMAudioDevice`.
 */
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
