//
//  AudioDevice+VirtualMasterOutput.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import AudioToolbox.AudioServices

// MARK: - 🔊 Virtual Master Output Volume / Balance Functions

public extension AudioDevice {
    /// Whether the master volume can be set for a given direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` when the volume can be set, `false` otherwise.
    func canSetVirtualMasterVolume(direction: Direction) -> Bool {
        guard validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                           scope: scope(direction: direction)) != nil else { return false }

        return true
    }

    /// Sets the virtual master volume for a given direction.
    ///
    /// - Parameter volume: The new volume as a scalar value ranging from 0 to 1.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setVirtualMasterVolume(_ volume: Float32, direction: Direction) -> Bool {
        guard let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                                         scope: scope(direction: direction)) else { return false }

        return setProperty(address: address, value: volume)
    }

    /// The virtual master scalar volume for a given direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `Float32` value with the scalar volume.
    func virtualMasterVolume(direction: Direction) -> Float32? {
        guard let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                                         scope: scope(direction: direction)) else { return nil }

        return getProperty(address: address)
    }

    /// The virtual master volume in decibels for a given direction.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `Float32` value with the volume in decibels.
    func virtualMasterVolumeInDecibels(direction: Direction) -> Float32? {
        var referenceChannel: UInt32

        if canSetVolume(channel: kAudioObjectPropertyElementMaster, direction: direction) {
            referenceChannel = kAudioObjectPropertyElementMaster
        } else {
            guard let channels = preferredChannelsForStereo(direction: direction) else { return nil }
            referenceChannel = channels.0
        }

        guard let masterVolume = virtualMasterVolume(direction: direction) else { return nil }

        return scalarToDecibels(volume: masterVolume, channel: referenceChannel, direction: direction)
    }

    /// The virtual master balance for a given direction.
    ///
    /// The range is from 0 (all power to the left) to 1 (all power to the right) with the value of 0.5 signifying
    /// that the channels have equal power.
    ///
    /// - Parameter direction: A direction.
    ///
    /// - Returns: *(optional)* A `Float32` value with the stereo balance.
    func virtualMasterBalance(direction: Direction) -> Float32? {
        guard let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterBalance,
                                         scope: scope(direction: direction)) else { return nil }

        return getProperty(address: address)
    }

    /// Sets the new virtual master balance for a given direction.
    ///
    /// The range is from 0 (all power to the left) to 1 (all power to the right) with the value of 0.5 signifying
    /// that the channels have equal power.
    ///
    /// - Parameter value: The new balance.
    /// - Parameter direction: A direction.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setVirtualMasterBalance(_ value: Float32, direction: Direction) -> Bool {
        guard let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterBalance,
                                         scope: scope(direction: direction)) else { return false }

        return setProperty(address: address, value: value)
    }
}
