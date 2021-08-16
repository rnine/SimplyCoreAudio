//
//  Element.swift
//
//  Created by Ruben Nine on 16/8/21.
//

import CoreAudio
import Foundation

public enum Element {
    case main

    @available(macOS, introduced: 10.0, deprecated: 12.0, renamed: "main")
    case master

    case custom(value: UInt32)
}

// MARK: - Internal Functions

extension Element {
    var asPropertyElement: AudioObjectPropertyElement {
        switch self {
        case .main:
            if #available(macOS 12, *) {
                return kAudioObjectPropertyElementMain
            } else {
                return kAudioObjectPropertyElementMaster
            }
        case .master:
            if #available(macOS 12, *) {
                return kAudioObjectPropertyElementMain
            } else {
                return kAudioObjectPropertyElementMaster
            }

        case .custom(let value): return value
        }
    }
}
