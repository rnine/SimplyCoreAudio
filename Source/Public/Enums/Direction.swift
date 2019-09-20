//
//  Direction.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 20/09/2019.
//  Copyright © 2019 9Labs. All rights reserved.
//

import Foundation

/// Indicates the direction used by an `AudioDevice` or `AudioStream`.
public enum Direction: String {
    /// Playback direction
    case playback
    /// Recording direction
    case recording
}
