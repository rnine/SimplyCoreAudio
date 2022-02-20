//
//  VolumeInfo.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import Foundation

/// This struct holds volume, mute, and playthrough information about a given channel and scope of an `AudioDevice`.
public struct VolumeInfo {
    /// Returns the device's volume for a given channel and scope.
    public var volume: Float32?

    /// Returns whether this device has volume for a given channel and scope.
    public var hasVolume: Bool = false

    /// Returns whether this device can set volume for a given channel and scope.
    public var canSetVolume: Bool = false

    /// Returns whether this device can mute audio for a given channel and scope.
    public var canMute: Bool = false

    /// Returns whether this device's audio is muted for a given channel and scope.
    public var isMuted: Bool = false

    /// Returns whether this device can play thru for a given channel and scope.
    public var canPlayThru: Bool = false

    /// Returns whether this device's play thru is set for a given channel and scope.
    public var isPlayThruSet: Bool = false
}
