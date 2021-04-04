//
//  SimplyCoreAudio.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import Atomics
import CoreAudio
import Foundation

/// This class provides convenient audio hardware-related functions (e.g. obtaining all devices managed by
/// [Core Audio](https://developer.apple.com/documentation/coreaudio)) and allows audio hardware-related notifications
/// to work. Additionally, you may create and remove aggregate devices using this class.
///
/// - Important: If you are interested in receiving hardware-related notifications, remember to keep a strong reference
/// to an object of this class.
public final class SimplyCoreAudio {
    // MARK: Public Properties

    // MARK: - Device Enumeration

    /// All the audio device identifiers currently available.
    ///
    /// - Note: This list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioObjectID` values.
    public var allDeviceIDs: [AudioObjectID] {
        hardware.allDeviceIDs
    }

    /// All the audio devices currently available.
    ///
    /// - Note: This list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allDevices: [AudioDevice] {
        hardware.allDevices
    }

    /// All the devices that have at least one input.
    ///
    /// - Note: This list may also include *Aggregate* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allInputDevices: [AudioDevice] {
        hardware.allInputDevices
    }

    /// All the devices that have at least one output.
    ///
    /// - Note: The list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allOutputDevices: [AudioDevice] {
        hardware.allOutputDevices
    }

    /// All the devices that support input and output.
    ///
    /// - Note: The list may also include *Aggregate* and *Multi-Output* devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allIODevices: [AudioDevice] {
        hardware.allIODevices
    }

    /// All the devices that are real devices — not aggregate ones.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allNonAggregateDevices: [AudioDevice] {
        hardware.allNonAggregateDevices
    }

    /// All the devices that are aggregate devices.
    ///
    /// - Returns: An array of `AudioDevice` objects.
    public var allAggregateDevices: [AudioDevice] {
        hardware.allAggregateDevices
    }

    // MARK: - Default Devices

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

    // MARK: - Private Static Properties

    private static var sharedHardware: AudioHardware!
    private static let instances = ManagedAtomic<Int>(0)

    // MARK: - Private Properties

    private let hardware: AudioHardware

    // MARK: - Lifecycle

    public init() {
        if Self.instances.load(ordering: .acquiring) == 0 {
            Self.sharedHardware = AudioHardware()
            Self.sharedHardware.enableDeviceMonitoring()
        }

        Self.instances.wrappingIncrement(ordering: .acquiring)

        hardware = Self.sharedHardware
    }

    deinit {
        Self.instances.wrappingDecrement(ordering: .acquiring)

        if Self.instances.load(ordering: .acquiring) == 0 {
            Self.sharedHardware.disableDeviceMonitoring()
            Self.sharedHardware = nil
        }
    }
}
