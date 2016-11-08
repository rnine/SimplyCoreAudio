//
//  Types.swift
//  AMCoreAudio
//
//  Created by Ruben on 7/7/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation

/**
    Represents a pair of stereo channel numbers.
 */
public typealias StereoPair = (left: UInt32, right: UInt32)

/**
    Indicates the direction used by an `AudioDevice` or `AudioStream`.
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
    Indicates the transport type used by an `AudioDevice`.
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
    Indicates the terminal type used by an `AudioStream`.
 */
public enum TerminalType: String {
    /**
        Unknown
     */
    case Unknown
    /**
        The ID for a terminal type of a line level stream. 
        Note that this applies to both input streams and output streams.
     */
    case Line
    /**
        A stream from/to a digital audio interface as defined by ISO 60958 (aka SPDIF or AES/EBU).
        Note that this applies to both input streams and output streams.
     */
    case DigitalAudioInterface
    /**
        Speaker
     */
    case Speaker
    /**
        Headphones
     */
    case Headphones
    /**
        Speaker for low frequency effects
     */
    case LFESpeaker
    /**
        A speaker on a telephone handset receiver
     */
    case ReceiverSpeaker
    /**
        A microphone
     */
    case Microphone
    /**
        A microphone attached to an headset
     */
    case HeadsetMicrophone
    /**
        A microphone on a telephone handset receiver
     */
    case ReceiverMicrophone
    /**
        A device providing a TTY signl
     */
    case TTY
    /**
        A stream from/to an HDMI port
     */
    case HDMI
    /**
        A stream from/to an DisplayPort port
     */
    case DisplayPort
}

/**
    This struct holds volume, mute, and playthru information about a given channel and direction of an `AudioDevice`.
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
