//
//  AudioDevice+VirtualMasterOutput.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import AudioToolbox
import CoreAudio
import Foundation

// MARK: - 🔊 Virtual Master Output Volume / Balance Functions

public extension AudioDevice {
    /// Whether the master volume can be set for a given scope.
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: `true` when the volume can be set, `false` otherwise.
    func canSetVirtualMasterVolume(scope: Scope) -> Bool {
        guard validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                           scope: propertyScope(from: scope)) != nil else { return false }

        return true
    }

    /// Sets the virtual master volume for a given scope.
    ///
    /// - Parameter volume: The new volume as a scalar value ranging from 0 to 1.
    /// - Parameter scope: A scope.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setVirtualMasterVolume(_ volume: Float32, scope: Scope) -> Bool {
        guard let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                                         scope: propertyScope(from: scope)) else { return false }

        return setProperty(address: address, value: volume)
    }

    /// The virtual master scalar volume for a given scope.
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: *(optional)* A `Float32` value with the scalar volume.
    func virtualMasterVolume(scope: Scope) -> Float32? {
        guard let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                                         scope: propertyScope(from: scope)) else { return nil }

        return getProperty(address: address)
    }

    /// The virtual master volume in decibels for a given scope.
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: *(optional)* A `Float32` value with the volume in decibels.
    func virtualMasterVolumeInDecibels(scope: Scope) -> Float32? {
        var referenceChannel: UInt32

        if canSetVolume(channel: kAudioObjectPropertyElementMaster, scope: scope) {
            referenceChannel = kAudioObjectPropertyElementMaster
        } else {
            guard let channels = preferredChannelsForStereo(scope: scope) else { return nil }
            referenceChannel = channels.0
        }

        guard let masterVolume = virtualMasterVolume(scope: scope) else { return nil }

        return scalarToDecibels(volume: masterVolume, channel: referenceChannel, scope: scope)
    }

    /// The virtual master balance for a given scope.
    ///
    /// The range is from 0 (all power to the left) to 1 (all power to the right) with the value of 0.5 signifying
    /// that the channels have equal power.
    ///
    /// - Parameter scope: A scope.
    ///
    /// - Returns: *(optional)* A `Float32` value with the stereo balance.
    func virtualMasterBalance(scope: Scope) -> Float32? {
        guard let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterBalance,
                                         scope: propertyScope(from: scope)) else { return nil }

        return getProperty(address: address)
    }

    /// Sets the new virtual master balance for a given scope.
    ///
    /// The range is from 0 (all power to the left) to 1 (all power to the right) with the value of 0.5 signifying
    /// that the channels have equal power.
    ///
    /// - Parameter value: The new balance.
    /// - Parameter scope: A scope.
    ///
    /// - Returns: `true` on success, `false` otherwise.
    @discardableResult func setVirtualMasterBalance(_ value: Float32, scope: Scope) -> Bool {
        guard let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterBalance,
                                         scope: propertyScope(from: scope)) else { return false }

        return setProperty(address: address, value: value)
    }
}
