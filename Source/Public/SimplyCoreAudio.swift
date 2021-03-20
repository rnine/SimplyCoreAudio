//
//  SimplyCoreAudio.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import Foundation
import AudioToolbox.AudioServices

public final class SimplyCoreAudio {
    // MARK: - Public Properties

    /// All the audio device identifiers currently available in the system.
    ///
    /// - Note: This list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioObjectID` values.
    public var allDeviceIDs: [AudioObjectID] {
        hardware.allDeviceIDs
    }

    /// All the audio devices currently available in the system.
    ///
    /// - Note: This list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allDevices: [AudioDevice] {
        hardware.allDevices
    }

    /// All the devices in the system that have at least one input.
    ///
    /// - Note: This list may also include *Aggregate* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allInputDevices: [AudioDevice] {
        hardware.allInputDevices
    }

    /// All the devices in the system that have at least one output.
    ///
    /// - Note: The list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allOutputDevices: [AudioDevice] {
        hardware.allOutputDevices
    }

    /// All the devices in the system that support input and output.
    ///
    /// - Note: The list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allIODevices: [AudioDevice] {
        hardware.allIODevices
    }

    /// All the devices in the system that are real devices - not aggregate ones.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allNonAggregateDevices: [AudioDevice] {
        hardware.allNonAggregateDevices
    }

    /// All the devices in the system that are aggregate devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allAggregateDevices: [AudioDevice] {
        hardware.allAggregateDevices
    }

    /// The default input device.
    ///
    /// - Returns: *(optional)* An `AudioDevice`.
    public var defaultInputDevice: AudioDevice? {
        hardware.defaultInputDevice
    }

    /// The default output device.
    ///
    /// - Returns: *(optional)* An `AudioDevice`.
    public var defaultOutputDevice: AudioDevice? {
        hardware.defaultOutputDevice
    }

    /// The default system output device.
    ///
    /// - Returns: *(optional)* An `AudioDevice`.
    public var defaultSystemOutputDevice: AudioDevice? {
        hardware.defaultSystemOutputDevice
    }

    // MARK: - Private Properties

    private let hardware = AudioHardware()

    // MARK: - Lifecycle

    init() {
        hardware.enableDeviceMonitoring()
    }

    deinit {
        hardware.disableDeviceMonitoring()
    }
}
