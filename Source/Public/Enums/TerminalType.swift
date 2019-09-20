//
//  TerminalType.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 20/09/2019.
//  Copyright © 2019 9Labs. All rights reserved.
//

import Foundation

/// Indicates the terminal type used by an `AudioStream`.
public enum TerminalType: String {
    /// Unknown
    case unknown

    /// The ID for a terminal type of a line level stream.
    /// Note that this applies to both input streams and output streams.
    case line

    /// A stream from/to a digital audio interface as defined by ISO 60958 (aka SPDIF or AES/EBU).
    /// Note that this applies to both input streams and output streams.
    case digitalAudioInterface

    /// Speaker
    case speaker

    /// Headphones
    case headphones

    /// Speaker for low frequency effects
    case lfeSpeaker

    /// A speaker on a telephone handset receiver
    case receiverSpeaker

    /// A microphone
    case microphone

    /// A microphone attached to an headset
    case headsetMicrophone

    /// A microphone on a telephone handset receiver
    case receiverMicrophone

    /// A device providing a TTY signl
    case tty

    /// A stream from/to an HDMI port
    case hdmi

    /// A stream from/to an DisplayPort port
    case displayPort
}
