//
//  TerminalType.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import CoreAudio
import Foundation

/// Indicates the terminal type used by an `AudioStream`.
public enum TerminalType: String {
    /// Unknown
    case unknown = "Unknown"

    /// The ID for a terminal type of a line level stream.
    /// Note that this applies to both input streams and output streams.
    case line = "Line"

    /// A stream from/to a digital audio interface as defined by ISO 60958 (aka SPDIF or AES/EBU).
    /// Note that this applies to both input streams and output streams.
    case digitalAudioInterface = "Digital Audio Interface"

    /// Speaker
    case speaker = "Speaker"

    /// Headphones
    case headphones = "Headphones"

    /// Speaker for low frequency effects
    case lfeSpeaker = "LFE Speaker"

    /// A speaker on a telephone handset receiver
    case receiverSpeaker = "Receiver Speaker"

    /// A microphone
    case microphone = "Microphone"

    /// A microphone attached to an headset
    case headsetMicrophone = "Headset Microphone"

    /// A microphone on a telephone handset receiver
    case receiverMicrophone = "Receiver Microphone"

    /// A device providing a TTY signal
    case tty = "TTY"

    /// A stream from/to an HDMI port
    case hdmi = "HDMI"

    /// A stream from/to an DisplayPort port
    case displayPort = "DisplayPort"
}

// MARK: - Internal Functions

extension TerminalType {
    static func from(_ constant: UInt32) -> TerminalType {
        switch constant {
        case kAudioStreamTerminalTypeLine:
            return .line
        case kAudioStreamTerminalTypeDigitalAudioInterface:
            return .digitalAudioInterface
        case kAudioStreamTerminalTypeSpeaker:
            return .speaker
        case kAudioStreamTerminalTypeHeadphones:
            return .headphones
        case kAudioStreamTerminalTypeLFESpeaker:
            return .lfeSpeaker
        case kAudioStreamTerminalTypeReceiverSpeaker:
            return .receiverSpeaker
        case kAudioStreamTerminalTypeMicrophone:
            return .microphone
        case kAudioStreamTerminalTypeHeadsetMicrophone:
            return .headsetMicrophone
        case kAudioStreamTerminalTypeReceiverMicrophone:
            return .receiverMicrophone
        case kAudioStreamTerminalTypeTTY:
            return .tty
        case kAudioStreamTerminalTypeHDMI:
            return .hdmi
        case kAudioStreamTerminalTypeDisplayPort:
            return .displayPort
        case kAudioStreamTerminalTypeUnknown:
            fallthrough
        default:
            return .unknown
        }
    }
}
