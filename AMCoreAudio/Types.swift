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
        Playback direction
     */
    case playback
    /**
        Recording direction
     */
    case recording
}

/**
    Indicates the transport type used by an `AudioDevice`.
 */
public enum TransportType: String {
    /**
        Unknown Transport Type
     */
    case unknown
    /**
        Built-In Transport Type
     */
    case builtIn
    /**
        Aggregate Transport Type
     */
    case aggregate
    /**
        Virtual Transport Type
     */
    case virtual
    /**
        PCI Transport Type
     */
    case pci
    /**
        USB Transport Type
     */
    case usb
    /**
        FireWire Transport Type
     */
    case fireWire
    /**
        Bluetooth Transport Type
     */
    case bluetooth
    /**
        Bluetooth LE Transport Type
     */
    case bluetoothLE
    /**
        HDMI Transport Type
     */
    case hdmi
    /**
        DisplayPort Transport Type
     */
    case displayPort
    /**
        AirPlay Transport Type
     */
    case airPlay
    /**
        Audio Video Bridging (AVB) Transport Type
     */
    case avb
    /**
        Thunderbolt Transport Type
     */
    case thunderbolt
}

/**
    Indicates the terminal type used by an `AudioStream`.
 */
public enum TerminalType: String {
    /**
        Unknown
     */
    case unknown
    /**
        The ID for a terminal type of a line level stream. 
        Note that this applies to both input streams and output streams.
     */
    case line
    /**
        A stream from/to a digital audio interface as defined by ISO 60958 (aka SPDIF or AES/EBU).
        Note that this applies to both input streams and output streams.
     */
    case digitalAudioInterface
    /**
        Speaker
     */
    case speaker
    /**
        Headphones
     */
    case headphones
    /**
        Speaker for low frequency effects
     */
    case lfeSpeaker
    /**
        A speaker on a telephone handset receiver
     */
    case receiverSpeaker
    /**
        A microphone
     */
    case microphone
    /**
        A microphone attached to an headset
     */
    case headsetMicrophone
    /**
        A microphone on a telephone handset receiver
     */
    case receiverMicrophone
    /**
        A device providing a TTY signl
     */
    case tty
    /**
        A stream from/to an HDMI port
     */
    case hdmi
    /**
        A stream from/to an DisplayPort port
     */
    case displayPort
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
