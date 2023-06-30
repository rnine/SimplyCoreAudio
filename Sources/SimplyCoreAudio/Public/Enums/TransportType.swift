//
//  TransportType.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import CoreAudio
import IOKit.audio

/// Indicates the transport type used by an `AudioDevice`.
public enum TransportType: String {
    /// Unknown Transport Type
    case unknown = "Unknown"

    /// Built-In Transport Type
    case builtIn = "Built-In"

    /// Aggregate Transport Type
    case aggregate = "Aggregate"

    /// Virtual Transport Type
    case virtual = "Virtual"

    /// PCI Transport Type
    case pci = "PCI"

    /// USB Transport Type
    case usb = "USB"

    /// FireWire Transport Type
    case fireWire = "FireWire"

    /// Bluetooth Transport Type
    case bluetooth = "Bluetooth"

    /// Bluetooth LE Transport Type
    case bluetoothLE = "Bluetooth LE"

    /// HDMI Transport Type
    case hdmi = "HDMI"

    /// DisplayPort Transport Type
    case displayPort = "DisplayPort"

    /// AirPlay Transport Type
    case airPlay = "AirPlay"

    /// Audio Video Bridging (AVB) Transport Type
    case avb = "AVB"

    /// Thunderbolt Transport Type
    case thunderbolt = "Thunderbolt"
    
    /// Network Transport Type
    case network = "Network"
    
    /// Other Transport Type
    case other = "Other"
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
        case UInt32(kIOAudioDeviceTransportTypeNetwork):
            return .network
        case UInt32(kIOAudioDeviceTransportTypeOther):
            return .other
        case kAudioDeviceTransportTypeUnknown:
            fallthrough
        default:
            return .unknown
        }
    }
}
