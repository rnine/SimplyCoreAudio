//
//  TransportType.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import CoreAudio
import Foundation

/// Indicates the transport type used by an `AudioDevice`.
public enum TransportType {
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

// MARK: - Internal Functions

extension TransportType {
    static func from(_ constant: UInt32) -> TransportType {
        switch constant {
        case kAudioDeviceTransportTypeBuiltIn:
            return .builtIn
        case kAudioDeviceTransportTypeAggregate:
            return .aggregate
        case kAudioDeviceTransportTypeVirtual:
            return .virtual
        case kAudioDeviceTransportTypePCI:
            return .pci
        case kAudioDeviceTransportTypeUSB:
            return .usb
        case kAudioDeviceTransportTypeFireWire:
            return .fireWire
        case kAudioDeviceTransportTypeBluetooth:
            return .bluetooth
        case kAudioDeviceTransportTypeBluetoothLE:
            return .bluetoothLE
        case kAudioDeviceTransportTypeHDMI:
            return .hdmi
        case kAudioDeviceTransportTypeDisplayPort:
            return .displayPort
        case kAudioDeviceTransportTypeAirPlay:
            return .airPlay
        case kAudioDeviceTransportTypeAVB:
            return .avb
        case kAudioDeviceTransportTypeThunderbolt:
            return .thunderbolt
        case kAudioDeviceTransportTypeUnknown:
            fallthrough
        default:
            return .unknown
        }
    }
}
