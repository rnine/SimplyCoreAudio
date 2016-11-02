//
//  ViewController.swift
//  AMCoreAudio Demo
//
//  Created by Ruben Nine on 30/10/2016.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Cocoa
import AMCoreAudio

class ViewController: NSViewController {

    @IBOutlet var deviceListPopUpButton: NSPopUpButton!
    @IBOutlet var deviceNameLabel: NSTextField!
    @IBOutlet var deviceManufacturerLabel: NSTextField!
    @IBOutlet var deviceIDLabel: NSTextField!
    @IBOutlet var deviceUIDLabel: NSTextField!
    @IBOutlet var deviceModelUIDLabel: NSTextField!
    @IBOutlet var deviceIsHiddenLabel: NSTextField!
    @IBOutlet var deviceTransportTypeLabel: NSTextField!
    @IBOutlet var deviceConfigAppLabel: NSTextField!
    @IBOutlet var deviceNominalSampleRatesPopupButton: NSPopUpButton!
    @IBOutlet var deviceActualSampleRateLabel: NSTextField!
    @IBOutlet var deviceClockSourcesPopupButton: NSPopUpButton!
    @IBOutlet var devicePlaybackLatencyLabel: NSTextField!
    @IBOutlet var deviceRecordingLatencyLabel: NSTextField!
    @IBOutlet var devicePlaybackSafetyOffsetLabel: NSTextField!
    @IBOutlet var deviceRecordingSafetyOffsetLabel: NSTextField!
    @IBOutlet var devicePlaybackMasterVolumeLabel: NSTextField!
    @IBOutlet var deviceRecordingMasterVolumeLabel: NSTextField!
    @IBOutlet var deviceHogModeLabel: NSTextField!
    @IBOutlet var deviceIsAliveLabel: NSTextField!
    @IBOutlet var deviceIsRunningLabel: NSTextField!
    @IBOutlet var deviceIsRunningSomewhereLabel: NSTextField!

    @IBOutlet var playbackStreamPopUpButton: NSPopUpButton!
    @IBOutlet var playbackStreamIDLabel: NSTextField!
    @IBOutlet var playbackStreamVirtualFormatPopUpButton: NSPopUpButton!
    @IBOutlet var playbackStreamPhysicalFormatPopUpButton: NSPopUpButton!

    @IBOutlet var recordingStreamPopUpButton: NSPopUpButton!
    @IBOutlet var recordingStreamIDLabel: NSTextField!
    @IBOutlet var recordingStreamVirtualFormatPopUpButton: NSPopUpButton!
    @IBOutlet var recordingStreamPhysicalFormatPopUpButton: NSPopUpButton!

    fileprivate let unknownValue = "<Unknown>"
    fileprivate let unsupportedValue = "<Unsupported>"

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            if let audioDevice = representedObject as? AMAudioDevice {
                populateDeviceInformation(device: audioDevice)
                populatePlaybackStreamPopUpButton(device: audioDevice)
                populateRecordingStreamPopUpButton(device: audioDevice)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Subscribe to events

        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioHardwareEvent.self, dispatchQueue: DispatchQueue.main)
        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioStreamEvent.self, dispatchQueue: DispatchQueue.main)

        // Populate device list
        populateDeviceList()

        // Set view controller's represented object
        if let selectedItem = deviceListPopUpButton.selectedItem {
            let deviceID = AudioObjectID(selectedItem.tag)
            representedObject = AMAudioDevice.lookupByID(deviceID)
        }
    }

    deinit {
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioHardwareEvent.self)
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioDeviceEvent.self)
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioStreamEvent.self)
    }

    // MARK: - Actions

    @IBAction func showDevice(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            let deviceID = AudioObjectID(item.tag)
            representedObject = AMAudioDevice.lookupByID(deviceID)
        }
    }

    @IBAction func updateSampleRate(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            if let sampleRate = item.representedObject as? Float64 {
                if let representedAudioDevice = representedObject as? AMAudioDevice {
                    if representedAudioDevice.setNominalSampleRate(sampleRate) == false {
                        print("Unable to set nominal sample rate.")
                    }
                }
            }
        }
    }

    @IBAction func updateClockSource(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            if let representedAudioDevice = representedObject as? AMAudioDevice {
                let clockSourceID = UInt32(item.tag)
                if representedAudioDevice.setClockSourceID(clockSourceID, forChannel: 0, andDirection: .Playback) == false {
                    print("Unable to set clock source to \(clockSourceID) on audio device \(representedAudioDevice)")
                }
            }
        }
    }

    @IBAction func updateStreamVirtualFormat(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            if let stream = AMAudioStream.lookupByID(AudioObjectID(item.tag)),
               let format = item.representedObject as? AudioStreamBasicDescription {
                stream.virtualFormat = format
            }
        }
    }

    @IBAction func updateStreamPhysicalFormat(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            if let stream = AMAudioStream.lookupByID(AudioObjectID(item.tag)),
                let format = item.representedObject as? AudioStreamBasicDescription {
                stream.physicalFormat = format
            }
        }
    }

    // MARK: - Private

    fileprivate func populateDeviceList() {
        deviceListPopUpButton.removeAllItems()

        for device in AMAudioDevice.allDevices() {
            deviceListPopUpButton.addItem(withTitle: device.deviceName())
            deviceListPopUpButton.lastItem?.tag = Int(device.deviceID)
        }

        if let representedAudioDevice = representedObject as? AMAudioDevice {
            self.deviceListPopUpButton.selectItem(withTag: Int(representedAudioDevice.deviceID))
        }
    }

    fileprivate func populateDeviceInformation(device: AMAudioDevice) {
        deviceNameLabel.stringValue = device.deviceName()
        deviceManufacturerLabel.stringValue = device.deviceManufacturer() ?? unknownValue
        deviceIDLabel.stringValue = "\(device.deviceID)"
        deviceUIDLabel.stringValue = device.deviceUID()!
        deviceModelUIDLabel.stringValue = device.deviceModelUID() ?? unknownValue
        deviceIsHiddenLabel.stringValue = booleanToString(bool: device.deviceIsHidden())
        deviceTransportTypeLabel.stringValue = device.transportType()?.rawValue ?? unknownValue
        deviceConfigAppLabel.stringValue = device.deviceConfigurationApplication() ?? unknownValue

        populateNominalSampleRatesPopUpButton(device: device)

        if let actualSampleRate = device.actualSampleRate() {
            deviceActualSampleRateLabel.stringValue = format(sampleRate: actualSampleRate)
        } else {
            deviceActualSampleRateLabel.stringValue = unknownValue
        }

        populateClockSourcesPopUpButton(device: device)

        if let playbackLatency = device.deviceLatencyFramesForDirection(.Playback) {
            devicePlaybackLatencyLabel.stringValue = "\(playbackLatency) frames"
        } else {
            devicePlaybackLatencyLabel.stringValue = unknownValue
        }

        if let recordingLatency = device.deviceLatencyFramesForDirection(.Playback) {
            deviceRecordingLatencyLabel.stringValue = "\(recordingLatency) frames"
        } else {
            deviceRecordingLatencyLabel.stringValue = unknownValue
        }

        if let playbackSafetyOffset = device.deviceSafetyOffsetFramesForDirection(.Playback) {
            devicePlaybackSafetyOffsetLabel.stringValue = "\(playbackSafetyOffset) frames"
        } else {
            devicePlaybackSafetyOffsetLabel.stringValue = unknownValue
        }

        if let recordingSafetyOffset = device.deviceSafetyOffsetFramesForDirection(.Recording) {
            deviceRecordingSafetyOffsetLabel.stringValue = "\(recordingSafetyOffset) frames"
        } else {
            deviceRecordingSafetyOffsetLabel.stringValue = unknownValue
        }

        populatePlaybackMasterVolume(device: device)
        populateRecordingMasterVolume(device: device)

        if let hogPID = device.hogModePID() {
            deviceHogModeLabel.stringValue = "\(hogPID)"
        } else {
            deviceHogModeLabel.stringValue = unknownValue
        }

        deviceIsAliveLabel.stringValue = booleanToString(bool: device.isAlive())
        deviceIsRunningLabel.stringValue = booleanToString(bool: device.isRunning())
        deviceIsRunningSomewhereLabel.stringValue = booleanToString(bool: device.isRunningSomewhere())
    }

    fileprivate func populateNominalSampleRatesPopUpButton(device: AMAudioDevice) {
        deviceNominalSampleRatesPopupButton.removeAllItems()

        if let sampleRates = device.nominalSampleRates(), sampleRates.count > 0 {
            deviceNominalSampleRatesPopupButton.isEnabled = true
            for sampleRate in sampleRates {
                deviceNominalSampleRatesPopupButton.addItem(withTitle: format(sampleRate: sampleRate))
                deviceNominalSampleRatesPopupButton.lastItem?.representedObject = sampleRate
            }

            if let nominalSampleRate = device.nominalSampleRate() {
                deviceNominalSampleRatesPopupButton.selectItem(withRepresentedObject: nominalSampleRate)
            }
        } else {
            deviceNominalSampleRatesPopupButton.addItem(withTitle: unsupportedValue)
            deviceNominalSampleRatesPopupButton.isEnabled = false
        }
    }

    fileprivate func populateClockSourcesPopUpButton(device: AMAudioDevice) {
        deviceClockSourcesPopupButton.removeAllItems()

        let direction: AMCoreAudio.Direction!

        switch (device.channelsForDirection(.Playback), device.channelsForDirection(.Recording)) {
        case let (p, _) where (p > 0):
            direction = .Playback
        case let (p, r) where (p == 0 && r > 0):
            direction = .Recording
        default:
            return // not supported
        }

        if let clockSourceIDs = device.clockSourceIDsForChannel(0, andDirection: direction), clockSourceIDs.count > 0 {
            deviceClockSourcesPopupButton.isEnabled = true
            for clockSourceID in clockSourceIDs {
                let clockSourceName = device.clockSourceNameForClockSourceID(clockSourceID, forChannel: 0, andDirection: direction) ?? "Internal"
                deviceClockSourcesPopupButton.addItem(withTitle: clockSourceName)
                deviceClockSourcesPopupButton.lastItem?.tag = Int(clockSourceID)
            }

            if let clockSourceID = device.clockSourceIDForChannel(0, andDirection: direction) {
                deviceClockSourcesPopupButton.selectItem(withTag: Int(clockSourceID))
            }
        } else {
            deviceClockSourcesPopupButton.addItem(withTitle: unsupportedValue)
            deviceClockSourcesPopupButton.isEnabled = false
        }
    }

    fileprivate func populatePlaybackStreamPopUpButton(device: AMAudioDevice) {
        playbackStreamPopUpButton.removeAllItems()

        if let playbackStreams = device.streamsForDirection(.Playback), playbackStreams.count > 0 {
            playbackStreamPopUpButton.isEnabled = true
            for stream in playbackStreams {
                playbackStreamPopUpButton.addItem(withTitle: "Output Stream \(format(id: stream.streamID))")
                playbackStreamPopUpButton.lastItem?.tag = Int(stream.streamID)
            }

            if let firstStream = playbackStreams.first {
                populatePlaybackStreamInfo(stream: firstStream)
            }
        } else {
            playbackStreamPopUpButton.addItem(withTitle: unsupportedValue)
            playbackStreamPopUpButton.isEnabled = false
            populatePlaybackStreamInfo(stream: nil)
        }
    }

    fileprivate func populateRecordingStreamPopUpButton(device: AMAudioDevice) {
        recordingStreamPopUpButton.removeAllItems()

        if let recordingStreams = device.streamsForDirection(.Recording), recordingStreams.count > 0 {
            recordingStreamPopUpButton.isEnabled = true
            for stream in recordingStreams {
                recordingStreamPopUpButton.addItem(withTitle: "Input Stream \(format(id: stream.streamID))")
                recordingStreamPopUpButton.lastItem?.tag = Int(stream.streamID)
            }

            if let firstStream = recordingStreams.first {
                populateRecordingStreamInfo(stream: firstStream)
            }
        } else {
            recordingStreamPopUpButton.addItem(withTitle: unsupportedValue)
            recordingStreamPopUpButton.isEnabled = false
            populateRecordingStreamInfo(stream: nil)
        }
    }

    fileprivate func populatePlaybackStreamInfo(stream: AMAudioStream?) {
        playbackStreamVirtualFormatPopUpButton.removeAllItems()
        playbackStreamPhysicalFormatPopUpButton.removeAllItems()

        if let stream = stream {
            playbackStreamIDLabel.stringValue = format(id: stream.streamID)
            if let virtualFormats = stream.availableVirtualFormatsMatchingCurrentNominalSampleRate(), virtualFormats.count > 0 {
                playbackStreamVirtualFormatPopUpButton.isEnabled = true
                for format in virtualFormats {
                    playbackStreamVirtualFormatPopUpButton.addItem(withTitle: "\(humanReadableStreamBasicDescription(asbd: format))")
                    playbackStreamVirtualFormatPopUpButton.lastItem?.tag = Int(stream.streamID)
                    playbackStreamVirtualFormatPopUpButton.lastItem?.representedObject = format
                }

                if let currentVirtualFormat = stream.virtualFormat {
                    let title = humanReadableStreamBasicDescription(asbd: currentVirtualFormat)
                    playbackStreamVirtualFormatPopUpButton.selectItem(withTitle: title)
                }
            } else {
                playbackStreamVirtualFormatPopUpButton.isEnabled = false
                playbackStreamVirtualFormatPopUpButton.removeAllItems()
            }

            if let physicalFormats = stream.availablePhysicalFormatsMatchingCurrentNominalSampleRate(), physicalFormats.count > 0 {
                playbackStreamPhysicalFormatPopUpButton.isEnabled = true
                for format in physicalFormats {
                    playbackStreamPhysicalFormatPopUpButton.addItem(withTitle: "\(humanReadableStreamBasicDescription(asbd: format))")
                    playbackStreamPhysicalFormatPopUpButton.lastItem?.tag = Int(stream.streamID)
                    playbackStreamPhysicalFormatPopUpButton.lastItem?.representedObject = format
                }

                if let currentPhysicalFormat = stream.physicalFormat {
                    let title = humanReadableStreamBasicDescription(asbd: currentPhysicalFormat)
                    playbackStreamPhysicalFormatPopUpButton.selectItem(withTitle: title)
                }
            } else {
                playbackStreamPhysicalFormatPopUpButton.isEnabled = false
                playbackStreamPhysicalFormatPopUpButton.removeAllItems()
            }
        } else {
            playbackStreamIDLabel.stringValue = unsupportedValue
            playbackStreamVirtualFormatPopUpButton.removeAllItems()
            playbackStreamVirtualFormatPopUpButton.isEnabled = false
            playbackStreamPhysicalFormatPopUpButton.removeAllItems()
            playbackStreamPhysicalFormatPopUpButton.isEnabled = false
        }
    }

    fileprivate func populateRecordingStreamInfo(stream: AMAudioStream?) {
        recordingStreamVirtualFormatPopUpButton.removeAllItems()
        recordingStreamPhysicalFormatPopUpButton.removeAllItems()

        if let stream = stream {
            recordingStreamIDLabel.stringValue = format(id: stream.streamID)
            if let virtualFormats = stream.availableVirtualFormatsMatchingCurrentNominalSampleRate(), virtualFormats.count > 0 {
                recordingStreamVirtualFormatPopUpButton.isEnabled = true
                for format in virtualFormats {
                    recordingStreamVirtualFormatPopUpButton.addItem(withTitle: "\(humanReadableStreamBasicDescription(asbd: format))")
                    recordingStreamVirtualFormatPopUpButton.lastItem?.tag = Int(stream.streamID)
                    recordingStreamVirtualFormatPopUpButton.lastItem?.representedObject = format
                }

                if let currentVirtualFormat = stream.virtualFormat {
                    let title = humanReadableStreamBasicDescription(asbd: currentVirtualFormat)
                    recordingStreamVirtualFormatPopUpButton.selectItem(withTitle: title)
                }
            } else {
                recordingStreamVirtualFormatPopUpButton.isEnabled = false
                recordingStreamVirtualFormatPopUpButton.removeAllItems()
            }

            if let physicalFormats = stream.availablePhysicalFormatsMatchingCurrentNominalSampleRate(), physicalFormats.count > 0 {
                recordingStreamPhysicalFormatPopUpButton.isEnabled = true
                for format in physicalFormats {
                    recordingStreamPhysicalFormatPopUpButton.addItem(withTitle: "\(humanReadableStreamBasicDescription(asbd: format))")
                    recordingStreamPhysicalFormatPopUpButton.lastItem?.tag = Int(stream.streamID)
                    recordingStreamPhysicalFormatPopUpButton.lastItem?.representedObject = format
                }

                if let currentPhysicalFormat = stream.physicalFormat {
                    let title = humanReadableStreamBasicDescription(asbd: currentPhysicalFormat)
                    recordingStreamPhysicalFormatPopUpButton.selectItem(withTitle: title)
                }
            } else {
                recordingStreamPhysicalFormatPopUpButton.isEnabled = false
                recordingStreamPhysicalFormatPopUpButton.removeAllItems()
            }
        } else {
            recordingStreamIDLabel.stringValue = unsupportedValue
            recordingStreamVirtualFormatPopUpButton.removeAllItems()
            recordingStreamVirtualFormatPopUpButton.isEnabled = false
            recordingStreamPhysicalFormatPopUpButton.removeAllItems()
            recordingStreamPhysicalFormatPopUpButton.isEnabled = false
        }
    }

    fileprivate func populatePlaybackMasterVolume(device: AMAudioDevice) {
        if let playbackMasterVolume = device.masterVolumeInDecibelsForDirection(.Playback) {
            let isMuted = (device.isMasterVolumeMutedForDirection(.Playback) ?? false)
            devicePlaybackMasterVolumeLabel.isEnabled = true
            devicePlaybackMasterVolumeLabel.stringValue = isMuted ? "Muted" : "\(playbackMasterVolume) dBfs"
        } else {
            devicePlaybackMasterVolumeLabel.stringValue = unknownValue
            devicePlaybackMasterVolumeLabel.isEnabled = false
        }
    }

    fileprivate func populateRecordingMasterVolume(device: AMAudioDevice) {
        if let recordingMasterVolume = device.masterVolumeInDecibelsForDirection(.Recording) {
            let isMuted = (device.isMasterVolumeMutedForDirection(.Recording) ?? false)
            deviceRecordingMasterVolumeLabel.isEnabled = true
            deviceRecordingMasterVolumeLabel.stringValue = isMuted ? "Muted" : "\(recordingMasterVolume) dBfs"
        } else {
            deviceRecordingMasterVolumeLabel.stringValue = unknownValue
            deviceRecordingMasterVolumeLabel.isEnabled = false
        }
    }

    fileprivate func booleanToString(bool: Bool) -> String {
        return bool == true ? "Yes" : "No"
    }

    fileprivate func format(sampleRate: Float64) -> String {
        return String(format: "%.1f kHz", sampleRate / 1000)
    }

    fileprivate func format(id: AudioObjectID) -> String {
        return String(format: "0x%X", Int(id))
    }

    fileprivate func humanReadableStreamBasicDescription(asbd: AudioStreamBasicDescription) -> String {
        var descriptionElements: [String] = [String]()

        // Mixable vs non-mixable
        if asbd.mFormatFlags & kAudioFormatFlagIsNonMixable == 0 {
            descriptionElements.append("Mixable")
        } else {
            descriptionElements.append("Unmixable")
        }

        // Amount of channels
        descriptionElements.append(String(format: "%d Channel", asbd.mChannelsPerFrame))

        // Bit depth
        descriptionElements.append(String(format: "%d Bit", asbd.mBitsPerChannel))

        // Signed integer vs floating point
        if asbd.mFormatFlags & kAudioFormatFlagIsSignedInteger == kAudioFormatFlagIsSignedInteger {
            descriptionElements.append("Signed Integer")
        } else if asbd.mFormatFlags & kAudioFormatFlagIsFloat == kAudioFormatFlagIsFloat {
            descriptionElements.append("Floating Point")
        }

        // Bit aligment
        if asbd.mFormatFlags & kLinearPCMFormatFlagIsPacked == 0 {
            if asbd.mFormatFlags & kAudioFormatFlagIsAlignedHigh == kAudioFormatFlagIsAlignedHigh {
                // Don't add to description
            } else {
                descriptionElements.append("Aligned Low in 32 Bits")
            }
        }

        return descriptionElements.joined(separator: " ")
    }
}

extension ViewController : AMEventSubscriber {

    func eventReceiver(_ event: AMEvent) {
        switch event {
        case let event as AMAudioDeviceEvent:
            switch event {
            case .nominalSampleRateDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    if let sampleRate = audioDevice.nominalSampleRate() {
                        deviceNominalSampleRatesPopupButton.selectItem(withRepresentedObject: sampleRate)

                        if let actualSampleRate = audioDevice.actualSampleRate() {
                            deviceActualSampleRateLabel.stringValue = format(sampleRate: actualSampleRate)
                        } else {
                            deviceActualSampleRateLabel.stringValue = unknownValue
                        }
                    }

                    populateRecordingStreamPopUpButton(device: audioDevice)
                    populatePlaybackStreamPopUpButton(device: audioDevice)
                }
            case .availableNominalSampleRatesDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    populateNominalSampleRatesPopUpButton(device: audioDevice)
                    populateRecordingStreamPopUpButton(device: audioDevice)
                    populatePlaybackStreamPopUpButton(device: audioDevice)
                }
            case .clockSourceDidChange(let audioDevice, let channel, let direction):
                if let clockSourceName = audioDevice.clockSourceForChannel(channel, andDirection: direction) {
                    print("\(audioDevice) clock source changed to \(clockSourceName)")
                }
            case .nameDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    deviceNameLabel.stringValue = audioDevice.deviceName()
                }

                if let item = deviceListPopUpButton.item(withTag: Int(audioDevice.deviceID)) {
                    item.title = audioDevice.deviceName()
                }
            case .listDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    populateDeviceInformation(device: audioDevice)
                }
            case .volumeDidChange(let audioDevice, _, let direction):
                if representedObject as? AMAudioDevice == audioDevice {
                    switch direction {
                    case .Playback:
                        populatePlaybackMasterVolume(device: audioDevice)
                    case .Recording:
                        populateRecordingMasterVolume(device: audioDevice)
                    case .Invalid:
                        break
                    }
                }
            case .muteDidChange(let audioDevice, _, let direction):
                if representedObject as? AMAudioDevice == audioDevice {
                    switch direction {
                    case .Playback:
                        populatePlaybackMasterVolume(device: audioDevice)
                    case .Recording:
                        populateRecordingMasterVolume(device: audioDevice)
                    case .Invalid:
                        break
                    }
                }
            case .isAliveDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    deviceIsAliveLabel.stringValue = booleanToString(bool: audioDevice.isAlive())
                }
            case .isRunningDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    deviceIsRunningLabel.stringValue = booleanToString(bool: audioDevice.isRunning())
                }
            case .isRunningSomewhereDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    deviceIsRunningSomewhereLabel.stringValue = booleanToString(bool: audioDevice.isRunningSomewhere())
                }
            }
        case let event as AMAudioHardwareEvent:
            switch event {
            case .deviceListChanged(_, _):
                self.populateDeviceList()
            case .defaultInputDeviceChanged(let audioDevice):
                print("Default input device changed to \(audioDevice)")
            case .defaultOutputDeviceChanged(let audioDevice):
                print("Default output device changed to \(audioDevice)")
            case .defaultSystemOutputDeviceChanged(let audioDevice):
                print("Default system output device changed to \(audioDevice)")
            }
        case let event as AMAudioStreamEvent:
            switch event {
            case .isActiveDidChange(let audioStream):
                print("Audio stream \(audioStream) active status changed to \(audioStream.active)")
            case .physicalFormatDidChange(let audioStream):
                if audioStream.owningDevice == representedObject as? AMAudioDevice {
                    switch audioStream.direction {
                    case .some(.Playback):
                        populatePlaybackStreamInfo(stream: audioStream)
                    case .some(.Recording):
                        populateRecordingStreamInfo(stream: audioStream)
                    default:
                        break
                    }
                }
            }
        default:
            break
        }
    }
}
