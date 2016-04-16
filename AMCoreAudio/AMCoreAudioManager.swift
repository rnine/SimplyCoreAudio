//
//  AMCoreAudioManager.swift
//  AMCoreAudio
//
//  Created by Ruben on 7/7/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation

/// `AMCoreAudioManagerDelegate` protocol
public protocol AMCoreAudioManagerDelegate: class {

    /**
        Called whenever the list of hardware devices and device subdevices changes.
        (i.e., devices that are part of *Aggregate* or *Multi-Output* devices.)
     */
    func hardwareDeviceListChangedWithAddedDevices(addedDevices: [AMCoreAudioDevice], andRemovedDevices removedDevices: [AMCoreAudioDevice])

    /**
        Called whenever the default input device changes.
     */
    func hardwareDefaultInputDeviceChanged(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the default output device changes.
     */
    func hardwareDefaultOutputDeviceChanged(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the default system device changes.
     */
    func hardwareDefaultSystemDeviceChanged(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's sample rate changes.
     */
    func audioDeviceNominalSampleRateDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's list of nominal sample rates changes.

        - Note: This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing 
        other audio devices (either *physical* or *virtual*.)
     */
    func audioDeviceAvailableNominalSampleRatesDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's clock source changes for a given channel and direction.
     */
    func audioDeviceClockSourceDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction)

    /**
        Called whenever the audio device's name changes.
     */
    func audioDeviceNameDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the list of owned audio devices on this audio device changes.

        - Note: This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other 
        audio devices (either *physical* or *virtual*.)
     */
    func audioDeviceListDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's volume for a given channel and direction changes.
     */
    func audioDeviceVolumeDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction)

    /**
        Called whenever the audio device's mute state for a given channel and direction changes.
     */
    func audioDeviceMuteDidChange(audioDevice: AMCoreAudioDevice, forChannel channel:UInt32, andDirection direction: Direction)

    /**
        Called whenever the audio device's *is alive* flag changes.
     */
    func audioDeviceIsAliveDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's *is running* flag changes.
     */
    func audioDeviceIsRunningDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's *is running somewhere* flag changes.
     */
    func audioDeviceIsRunningSomewhereDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio stream `isActive` flag changes state.
     */
    func audioStreamIsActiveDidChange(audioStream: AMCoreAudioStream)

    /**
        Called whenever the audio stream physical format changes.
     */
    func audioStreamPhysicalFormatDidChange(audioStream: AMCoreAudioStream)
}

/// Optional `AMCoreAudioManagerDelegate` protocol functions
public extension AMCoreAudioManagerDelegate {

    func hardwareDeviceListChangedWithAddedDevices(addedDevices: [AMCoreAudioDevice], andRemovedDevices removedDevices: [AMCoreAudioDevice]) {}
    func hardwareDefaultInputDeviceChanged(audioDevice: AMCoreAudioDevice) {}
    func hardwareDefaultOutputDeviceChanged(audioDevice: AMCoreAudioDevice) {}
    func hardwareDefaultSystemDeviceChanged(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceNominalSampleRateDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceAvailableNominalSampleRatesDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceClockSourceDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction) {}
    func audioDeviceNameDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceListDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceVolumeDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction) {}
    func audioDeviceMuteDidChange(audioDevice: AMCoreAudioDevice, forChannel channel:UInt32, andDirection direction: Direction) {}
    func audioDeviceIsAliveDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceIsRunningDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceIsRunningSomewhereDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioStreamIsActiveDidChange(audioStream: AMCoreAudioStream) {}
    func audioStreamPhysicalFormatDidChange(audioStream: AMCoreAudioStream) {}
}


/**
   `AMCoreAudioManager`

    This class simplifies the process of receiving notifications coming from the following sources:

    1. Audio devices (`AMCoreAudioDevice`)
    2. Audio hardware (`AMCoreAudioHardware`)
    3. Audio streams (`AMCoreAudioStream`)

    To receive notifications from any of these sources, you'll simply need to implement
    the `AMCoreAudioManagerDelegate` protocol in your delegate class.
 */
final public class AMCoreAudioManager: NSObject {

    // MARK: - Properties

    /**
        A singleton instance of `AMCoreAudioManager`.
     */
    public static let sharedManager = AMCoreAudioManager()

    /**
        A delegate conforming to the `AMCoreAudioManagerDelegate` protocol.
     */
    public weak var delegate: AMCoreAudioManagerDelegate?

    /**
        An auto-maintained array of all the audio devices currently available in the system.

        - Note: This list may also include *Aggregate* and *Multi-Output* devices.

        - Returns: An array of `AMCoreAudioDevice` objects.
     */
    public var allKnownDevices: [AMCoreAudioDevice] {
        get {
            return Array(allDevicesAndStreams.keys)
        }
    }

    private var allDevicesAndStreams = [AMCoreAudioDevice: [AMCoreAudioStream]]()
    private var audioHardware = AMCoreAudioHardware()

    // MARK: - Public Functions

    private override init() {
        super.init()
        setup()
    }

    deinit {
        cleanup()
    }

    // MARK: - Private Functions

    private func setup() {
        let allDevices = AMCoreAudioDevice.allDevices()

        allDevices.forEach { (device) in
            addDevice(device)
        }

        audioHardware.delegate = self
    }

    private func cleanup() {
        allKnownDevices.forEach { (device) in
            removeDevice(device)
        }

        audioHardware.delegate = nil
    }

    private func addDevice(device: AMCoreAudioDevice) {
        let playbackStreams = device.streamsForDirection(.Playback) ?? []
        let recordingStreams = device.streamsForDirection(.Recording) ?? []
        let streams = playbackStreams + recordingStreams

        allDevicesAndStreams[device] = streams

        device.delegate = self

        streams.forEach { (stream) in
            stream.delegate = self
        }
    }

    private func removeDevice(device: AMCoreAudioDevice) {
        if let streams = allDevicesAndStreams[device] {
            streams.forEach({ (stream) in
                stream.delegate = nil
            })

            device.delegate = nil

            allDevicesAndStreams.removeValueForKey(device)
        }
    }
}

extension AMCoreAudioManager: AMCoreAudioDeviceDelegate {

    public func audioDeviceNominalSampleRateDidChange(audioDevice: AMCoreAudioDevice) {
        delegate?.audioDeviceNominalSampleRateDidChange(audioDevice)
    }

    public func audioDeviceAvailableNominalSampleRatesDidChange(audioDevice: AMCoreAudioDevice) {
        delegate?.audioDeviceAvailableNominalSampleRatesDidChange(audioDevice)
    }

    public func audioDeviceClockSourceDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction) {
        delegate?.audioDeviceClockSourceDidChange(audioDevice, forChannel: channel, andDirection: direction)
    }

    public func audioDeviceNameDidChange(audioDevice: AMCoreAudioDevice) {
        delegate?.audioDeviceNameDidChange(audioDevice)
    }

    public func audioDeviceListDidChange(audioDevice: AMCoreAudioDevice) {
        delegate?.audioDeviceListDidChange(audioDevice)
    }

    public func audioDeviceVolumeDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction) {
        delegate?.audioDeviceVolumeDidChange(audioDevice, forChannel: channel, andDirection: direction)
    }

    public func audioDeviceMuteDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction) {
        delegate?.audioDeviceMuteDidChange(audioDevice, forChannel: channel, andDirection: direction)
    }

    public func audioDeviceIsAliveDidChange(audioDevice: AMCoreAudioDevice) {
        delegate?.audioDeviceIsAliveDidChange(audioDevice)
    }

    public func audioDeviceIsRunningDidChange(audioDevice: AMCoreAudioDevice) {
        delegate?.audioDeviceIsRunningDidChange(audioDevice)
    }

    public func audioDeviceIsRunningSomewhereDidChange(audioDevice: AMCoreAudioDevice) {
        delegate?.audioDeviceIsRunningSomewhereDidChange(audioDevice)
    }
}

extension AMCoreAudioManager: AMCoreAudioHardwareDelegate {

    public func hardwareDeviceListChanged(audioHardware: AMCoreAudioHardware) {
        // Get the latest device list
        let latestDeviceList = AMCoreAudioDevice.allDevices()

        let addedDevices = latestDeviceList.filter { (audioDevice) -> Bool in
            let isContained = allKnownDevices.filter({ (oldAudioDevice) -> Bool in
                return oldAudioDevice == audioDevice
            }).count > 0

            return !isContained
        }

        let removedDevices = allKnownDevices.filter { (audioDevice) -> Bool in
            let isContained = latestDeviceList.filter({ (oldAudioDevice) -> Bool in
                return oldAudioDevice == audioDevice
            }).count > 0

            return !isContained
        }

        // Add new devices
        addedDevices.forEach { (device) in
            addDevice(device)
        }

        // Remove old devices
        removedDevices.forEach { (device) in
            removeDevice(device)
        }

        // Notify our delegate
        delegate?.hardwareDeviceListChangedWithAddedDevices(addedDevices, andRemovedDevices: removedDevices)
    }

    public func hardwareDefaultInputDeviceChanged(audioHardware: AMCoreAudioHardware) {
        if let audioDevice = AMCoreAudioDevice.defaultInputDevice() {
            delegate?.hardwareDefaultInputDeviceChanged(audioDevice)
        }
    }

    public func hardwareDefaultOutputDeviceChanged(audioHardware: AMCoreAudioHardware) {
        if let audioDevice = AMCoreAudioDevice.defaultOutputDevice() {
            delegate?.hardwareDefaultOutputDeviceChanged(audioDevice)
        }
    }

    public func hardwareDefaultSystemDeviceChanged(audioHardware: AMCoreAudioHardware) {
        if let audioDevice = AMCoreAudioDevice.defaultSystemOutputDevice() {
            delegate?.hardwareDefaultSystemDeviceChanged(audioDevice)
        }
    }
}

extension AMCoreAudioManager : AMCoreAudioStreamDelegate {

    public func audioStreamIsActiveDidChange(audioStream: AMCoreAudioStream) {
        delegate?.audioStreamIsActiveDidChange(audioStream)
    }

    public func audioStreamPhysicalFormatDidChange(audioStream: AMCoreAudioStream) {
        delegate?.audioStreamPhysicalFormatDidChange(audioStream)
    }
}
