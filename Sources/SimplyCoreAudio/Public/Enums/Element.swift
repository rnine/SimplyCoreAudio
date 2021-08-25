//
//  Element.swift
//
//  Created by Ruben Nine on 16/8/21.
//

import CoreAudio
import Foundation
@_implementationOnly import SimplyCoreAudioC

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
        case .master:
            fallthrough
        case .main:
            // defined in SimpleCoreAudioC for pre os 12
            return kAudioObjectPropertyElementMain
        case let .custom(value): return value
        }
    }
}
