//
//  AudioDevice+GeneralInformation.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import AudioToolbox.AudioServices

// MARK: - ✪ General Device Information Functions

public extension AudioDevice {
    /// The audio device's identifier (ID).
    ///
    /// - Note: This identifier will change with system restarts.
    /// If you need an unique identifier that persists between restarts, use `uid` instead.
    ///
    /// - SeeAlso: `uid`
    ///
    /// - Returns: An audio device identifier.
    var id: AudioObjectID { objectID }

    /// The audio device's unique identifier (UID).
    ///
    /// - Note: This identifier is guaranted to uniquely identify a device in Core Audio
    /// and will not change even after restarts. Two (or more) identical audio devices
    /// are also guaranteed to have unique identifiers.
    ///
    /// - SeeAlso: `id`
    ///
    /// - Returns: *(optional)* A `String` with the audio device `UID`.
    var uid: String? {
        if let address = validAddress(selector: kAudioDevicePropertyDeviceUID) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /// The audio device's model unique identifier.
    ///
    /// - Returns: *(optional)* A `String` with the audio device's model unique identifier.
    var modelUID: String? {
        if let address = validAddress(selector: kAudioDevicePropertyModelUID) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /// The audio device's manufacturer.
    ///
    /// - Returns: *(optional)* A `String` with the audio device's manufacturer name.
    var manufacturer: String? {
        if let address = validAddress(selector: kAudioObjectPropertyManufacturer) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /// The bundle identifier for an application that provides a GUI for configuring the AudioDevice.
    /// By default, the value of this property is the bundle ID for *Audio MIDI Setup*.
    ///
    /// - Returns: *(optional)* A `String` pointing to the bundle identifier
    var configurationApplication: String? {
        if let address = validAddress(selector: kAudioDevicePropertyConfigurationApplication) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /// A transport type that indicates how the audio device is connected to the CPU.
    ///
    /// - Returns: *(optional)* A `TransportType`.
    var transportType: TransportType? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var transportType = UInt32(0)

        guard noErr == getPropertyData(address, andValue: &transportType) else { return nil }

        switch transportType {
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

    /// Whether the audio device is included in the normal list of devices.
    ///
    /// - Note: Hidden devices can only be discovered by knowing their `UID` and
    /// using `kAudioHardwarePropertyDeviceForUID`.
    ///
    /// - Returns: `true` when device is hidden, `false` otherwise.
    var isHidden: Bool {
        if let address = validAddress(selector: kAudioDevicePropertyIsHidden) {
            return getProperty(address: address) ?? false
        } else {
            return false
        }
    }

    /// Whether the device is alive.
    ///
    /// - Returns: `true` when the device is alive, `false` otherwise.
    var isAlive: Bool {
        if let address = validAddress(selector: kAudioDevicePropertyDeviceIsAlive) {
            return getProperty(address: address) ?? false
        } else {
            return false
        }
    }

    /// Whether the device is running.
    ///
    /// - Returns: `true` when the device is running, `false` otherwise.
    var isRunning: Bool {
        if let address = validAddress(selector: kAudioDevicePropertyDeviceIsRunning) {
            return getProperty(address: address) ?? false
        } else {
            return false
        }
    }

    /// Whether the device is running somewhere.
    ///
    /// - Returns: `true` when the device is running somewhere, `false` otherwise.
    var isRunningSomewhere: Bool {
        if let address = validAddress(selector: kAudioDevicePropertyDeviceIsRunningSomewhere) {
            return getProperty(address: address) ?? false
        } else {
            return false
        }
    }

    /// All the audio object identifiers that are owned by this audio device.
    ///
    /// - Returns: *(optional)* An array of `AudioObjectID` values.
    var ownedObjectIDs: [AudioObjectID]? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyOwnedObjects,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var qualifierData = [kAudioObjectClassID]
        let qualifierDataSize = UInt32(MemoryLayout<AudioClassID>.size * qualifierData.count)
        var ownedObjects = [AudioObjectID]()

        let status = getPropertyDataArray(address,
                                          qualifierDataSize: qualifierDataSize,
                                          qualifierData: &qualifierData,
                                          value: &ownedObjects,
                                          andDefaultValue: AudioObjectID())

        return noErr == status ? ownedObjects : nil
    }

    /// All the audio object identifiers representing the audio controls of this audio device.
    ///
    /// - Returns: *(optional)* An array of `AudioObjectID` values.
    var controlList: [AudioObjectID]? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyControlList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var controlList = [AudioObjectID]()
        let status = getPropertyDataArray(address, value: &controlList, andDefaultValue: AudioObjectID())

        return noErr == status ? controlList : nil
    }

    /// All the audio devices related to this audio device.
    ///
    /// - Returns: *(optional)* An array of `AudioDevice` objects.
    var relatedDevices: [AudioDevice]? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyRelatedDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var relatedDevices = [AudioDeviceID]()
        let status = getPropertyDataArray(address, value: &relatedDevices, andDefaultValue: AudioDeviceID())

        if noErr == status {
            return relatedDevices.compactMap { AudioDevice.lookup(by: $0) }
        }

        return nil
    }
}
