//
//  VolumeInfo.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import Foundation

/// This struct holds volume, mute, and playthru information about a given channel and scope of an `AudioDevice`.
public struct VolumeInfo {
    /// Returns an scalar volume, or `nil` if unavailable.
    public var volume: Float32?

    /// Returns whether volume is present.
    public var hasVolume: Bool = false

    /// Returns whether volume can be set.
    public var canSetVolume: Bool = false

    /// Returns whether audio can be muted.
    public var canMute: Bool = false

    /// Returns whether audio is muted.
    public var isMuted: Bool = false

    /// Returns whether play thru is supported.
    public var canPlayThru: Bool = false

    /// Returns whether play thru is enabled.
    public var isPlayThruSet: Bool = false
}
