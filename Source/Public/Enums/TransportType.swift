//
//  TransportType.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 20/09/2019.
//  Copyright © 2019 9Labs. All rights reserved.
//

import Foundation

/// Indicates the transport type used by an `AudioDevice`.
public enum TransportType: String {
    /// Unknown Transport Type
    case unknown

    /// Built-In Transport Type
    case builtIn

    /// Aggregate Transport Type
    case aggregate

    /// Virtual Transport Type
    case virtual

    /// PCI Transport Type
    case pci

    /// USB Transport Type
    case usb

    /// FireWire Transport Type
    case fireWire

    /// Bluetooth Transport Type
    case bluetooth

    /// Bluetooth LE Transport Type
    case bluetoothLE

    /// HDMI Transport Type
    case hdmi

    /// DisplayPort Transport Type
    case displayPort

    /// AirPlay Transport Type
    case airPlay

    /// Audio Video Bridging (AVB) Transport Type
    case avb

    /// Thunderbolt Transport Type
    case thunderbolt
}
