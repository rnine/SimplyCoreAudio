//
//  AudioDevice+GeneralInformation.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import Foundation

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
    /// - Note: This identifier is guaranteed to uniquely identify a device in Core Audio
    /// and will not change even after restarts. Two (or more) identical audio devices
    /// are also guaranteed to have unique identifiers.
    ///
    /// - SeeAlso: `id`
    ///
    /// - Returns: *(optional)* A `String` with the audio device `UID`.
    var uid: String? {
        guard let address = validAddress(selector: kAudioDevicePropertyDeviceUID) else { return nil }
        return getProperty(address: address)
    }

    /// The audio device's model unique identifier.
    ///
    /// - Returns: *(optional)* A `String` with the audio device's model unique identifier.
    var modelUID: String? {
        guard let address = validAddress(selector: kAudioDevicePropertyModelUID) else { return nil }
        return getProperty(address: address)
    }

    /// The audio device's manufacturer.
    ///
    /// - Returns: *(optional)* A `String` with the audio device's manufacturer name.
    var manufacturer: String? {
        guard let address = validAddress(selector: kAudioObjectPropertyManufacturer) else { return nil }
        return getProperty(address: address)
    }

    /// The bundle identifier for an application that provides a GUI for configuring the AudioDevice.
    /// By default, the value of this property is the bundle ID for *Audio MIDI Setup*.
    ///
    /// - Returns: *(optional)* A `String` pointing to the bundle identifier
    var configurationApplication: String? {
        guard let address = validAddress(selector: kAudioDevicePropertyConfigurationApplication) else { return nil }
        return getProperty(address: address)
    }

    /// Whether the audio device is included in the normal list of devices.
    ///
    /// - Note: Hidden devices can only be discovered by knowing their `UID` and
    /// using `kAudioHardwarePropertyDeviceForUID`.
    ///
    /// - Returns: `true` when device is hidden, `false` otherwise.
    var isHidden: Bool {
        guard let address = validAddress(selector: kAudioDevicePropertyIsHidden) else { return false }
        return getProperty(address: address) ?? false
    }

    /// Whether the device is alive.
    ///
    /// - Returns: `true` when the device is alive, `false` otherwise.
    var isAlive: Bool {
        guard let address = validAddress(selector: kAudioDevicePropertyDeviceIsAlive) else { return false }
        return getProperty(address: address) ?? false
    }

    /// Whether the device is running.
    ///
    /// - Returns: `true` when the device is running, `false` otherwise.
    var isRunning: Bool {
        guard let address = validAddress(selector: kAudioDevicePropertyDeviceIsRunning) else { return false }
        return getProperty(address: address) ?? false
    }

    /// Whether the device is running somewhere.
    ///
    /// - Returns: `true` when the device is running somewhere, `false` otherwise.
    var isRunningSomewhere: Bool {
        guard let address = validAddress(selector: kAudioDevicePropertyDeviceIsRunningSomewhere) else { return false }
        return getProperty(address: address) ?? false
    }

    /// A transport type that indicates how the audio device is connected to the CPU.
    ///
    /// - Returns: *(optional)* A `TransportType`.
    var transportType: TransportType? {
        guard let address = validAddress(selector: kAudioDevicePropertyTransportType) else { return nil }

        if let transportType: UInt32 = getProperty(address: address) {
            return .from(transportType)
        } else {
            return nil
        }
    }

    /// All the audio object identifiers that are owned by this audio device.
    ///
    /// - Returns: *(optional)* An array of `AudioObjectID` values.
    var ownedObjectIDs: [AudioObjectID]? {
        guard let address = validAddress(selector: kAudioObjectPropertyOwnedObjects) else { return nil }

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
        guard let address = validAddress(selector: kAudioObjectPropertyControlList) else { return nil }

        var controlList = [AudioObjectID]()
        let status = getPropertyDataArray(address, value: &controlList, andDefaultValue: AudioObjectID())

        return noErr == status ? controlList : nil
    }

    /// All the audio devices related to this audio device.
    ///
    /// - Returns: *(optional)* An array of `AudioDevice` objects.
    var relatedDevices: [AudioDevice]? {
        guard let address = validAddress(selector: kAudioDevicePropertyRelatedDevices) else { return nil }

        var relatedDevices = [AudioDeviceID]()
        let status = getPropertyDataArray(address, value: &relatedDevices, andDefaultValue: AudioDeviceID())

        if noErr == status {
            return relatedDevices.compactMap { AudioDevice.lookup(by: $0) }
        }

        return nil
    }
}
