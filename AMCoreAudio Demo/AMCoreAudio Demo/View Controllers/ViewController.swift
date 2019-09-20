//
//  ViewController.swift
//  AMCoreAudio Demo
//
//  Created by Ruben Nine on 30/10/2016.
//  Copyright © 2016 9Labs. All rights reserved.
//

import AMCoreAudio
import Cocoa

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
    @IBOutlet var deviceHogModeLabel: NSTextField!
    @IBOutlet var deviceIsAliveLabel: NSTextField!
    @IBOutlet var deviceIsRunningLabel: NSTextField!
    @IBOutlet var deviceIsRunningSomewhereLabel: NSTextField!

    @IBOutlet var playbackStreamPopUpButton: NSPopUpButton!
    @IBOutlet var playbackStreamIDLabel: NSTextField!
    @IBOutlet var playbackStreamStartingChannelLabel: NSTextField!
    @IBOutlet var playbackStreamTerminalTypeLabel: NSTextField!
    @IBOutlet var playbackStreamVirtualFormatPopUpButton: NSPopUpButton!
    @IBOutlet var playbackStreamPhysicalFormatPopUpButton: NSPopUpButton!

    @IBOutlet var recordingStreamPopUpButton: NSPopUpButton!
    @IBOutlet var recordingStreamIDLabel: NSTextField!
    @IBOutlet var recordingStreamStartingChannelLabel: NSTextField!
    @IBOutlet var recordingStreamTerminalTypeLabel: NSTextField!
    @IBOutlet var recordingStreamVirtualFormatPopUpButton: NSPopUpButton!
    @IBOutlet var recordingStreamPhysicalFormatPopUpButton: NSPopUpButton!

    fileprivate let unknownValue = "<Unknown>"
    fileprivate let unsupportedValue = "<Unsupported>"

    private weak var inputViewController: ExtraViewController?
    private weak var outputViewController: ExtraViewController?

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            if let audioDevice = representedObject as? AudioDevice {
                populateDeviceInformation(device: audioDevice)
                populatePlaybackStreamPopUpButton(device: audioDevice)
                populateRecordingStreamPopUpButton(device: audioDevice)

                // Propagate representedObject changes in child controllers
                inputViewController?.representedObject = audioDevice
                outputViewController?.representedObject = audioDevice
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Subscribe to events

        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioHardwareEvent.self, dispatchQueue: DispatchQueue.main)
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioStreamEvent.self, dispatchQueue: DispatchQueue.main)

        // Populate device list
        populateDeviceList()

        // Set view controller's represented object
        if let selectedItem = deviceListPopUpButton.selectedItem {
            let deviceID = AudioObjectID(selectedItem.tag)
            representedObject = AudioDevice.lookup(by: deviceID)
        }
    }

    deinit {
        NotificationCenter.defaultCenter.unsubscribe(self, eventType: AudioHardwareEvent.self)
        NotificationCenter.defaultCenter.unsubscribe(self, eventType: AudioDeviceEvent.self)
        NotificationCenter.defaultCenter.unsubscribe(self, eventType: AudioStreamEvent.self)
    }

    override func prepare(for segue: NSStoryboardSegue, sender _: Any?) {
        switch segue.identifier {
        case .some("Input"):
            if let dc = segue.destinationController as? ExtraViewController {
                inputViewController = dc
                dc.representedDirection = .recording
            }
        case .some("Output"):
            if let dc = segue.destinationController as? ExtraViewController {
                outputViewController = dc
                dc.representedDirection = .playback
            }
        default:
            break
        }
    }

    // MARK: - Actions

    @IBAction func showDevice(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            let deviceID = AudioObjectID(item.tag)
            representedObject = AudioDevice.lookup(by: deviceID)
        }
    }

    @IBAction func updateSampleRate(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            if let sampleRate = item.representedObject as? Float64 {
                if let representedAudioDevice = representedObject as? AudioDevice {
                    if representedAudioDevice.setNominalSampleRate(sampleRate) == false {
                        print("Unable to set nominal sample rate.")
                    }
                }
            }
        }
    }

    @IBAction func updateClockSource(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            if let representedAudioDevice = representedObject as? AudioDevice {
                let clockSourceID = UInt32(item.tag)
                if representedAudioDevice.setClockSourceID(clockSourceID) == false {
                    print("Unable to set clock source to \(clockSourceID) on audio device \(representedAudioDevice)")
                }
            }
        }
    }

    @IBAction func updateStreamVirtualFormat(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            if let stream = AudioStream.lookup(by: AudioObjectID(item.tag)),
                let format = item.representedObject as? AudioStreamBasicDescription {
                stream.virtualFormat = format
            }
        }
    }

    @IBAction func updateStreamPhysicalFormat(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            if let stream = AudioStream.lookup(by: AudioObjectID(item.tag)),
                let format = item.representedObject as? AudioStreamBasicDescription {
                stream.physicalFormat = format
            }
        }
    }

    @IBAction func selectPlaybackStream(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            if let stream = AudioStream.lookup(by: AudioObjectID(item.tag)) {
                populatePlaybackStreamInfo(stream: stream)
            }
        }
    }

    @IBAction func selectRecordingStream(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            if let stream = AudioStream.lookup(by: AudioObjectID(item.tag)) {
                populateRecordingStreamInfo(stream: stream)
            }
        }
    }

    // MARK: - Private

    fileprivate func populateDeviceList() {
        deviceListPopUpButton.removeAllItems()

        for device in AudioDevice.allDevices() {
            deviceListPopUpButton.addItem(withTitle: device.name)
            deviceListPopUpButton.lastItem?.tag = Int(device.id)
        }

        if let representedAudioDevice = representedObject as? AudioDevice {
            self.deviceListPopUpButton.selectItem(withTag: Int(representedAudioDevice.id))
        }
    }

    fileprivate func populateDeviceInformation(device: AudioDevice) {
        deviceNameLabel.stringValue = device.name
        deviceManufacturerLabel.stringValue = device.manufacturer ?? unknownValue
        deviceIDLabel.stringValue = "\(device.id)"
        deviceUIDLabel.stringValue = device.uid!
        deviceModelUIDLabel.stringValue = device.modelUID ?? unknownValue
        deviceIsHiddenLabel.stringValue = booleanToString(bool: device.isHidden())
        deviceTransportTypeLabel.stringValue = device.transportType?.rawValue ?? unknownValue
        deviceConfigAppLabel.stringValue = device.configurationApplication ?? unknownValue

        populateNominalSampleRatesPopUpButton(device: device)

        if let actualSampleRate = device.actualSampleRate() {
            deviceActualSampleRateLabel.stringValue = format(sampleRate: actualSampleRate)
        } else {
            deviceActualSampleRateLabel.stringValue = unknownValue
        }

        populateClockSourcesPopUpButton(device: device)

        if let playbackLatency = device.latency(direction: .playback) {
            devicePlaybackLatencyLabel.stringValue = "\(playbackLatency) frames"
        } else {
            devicePlaybackLatencyLabel.stringValue = unknownValue
        }

        if let recordingLatency = device.latency(direction: .playback) {
            deviceRecordingLatencyLabel.stringValue = "\(recordingLatency) frames"
        } else {
            deviceRecordingLatencyLabel.stringValue = unknownValue
        }

        if let playbackSafetyOffset = device.safetyOffset(direction: .playback) {
            devicePlaybackSafetyOffsetLabel.stringValue = "\(playbackSafetyOffset) frames"
        } else {
            devicePlaybackSafetyOffsetLabel.stringValue = unknownValue
        }

        if let recordingSafetyOffset = device.safetyOffset(direction: .recording) {
            deviceRecordingSafetyOffsetLabel.stringValue = "\(recordingSafetyOffset) frames"
        } else {
            deviceRecordingSafetyOffsetLabel.stringValue = unknownValue
        }

        if let hogPID = device.hogModePID() {
            deviceHogModeLabel.stringValue = "\(hogPID)"
        } else {
            deviceHogModeLabel.stringValue = unknownValue
        }

        deviceIsAliveLabel.stringValue = booleanToString(bool: device.isAlive())
        deviceIsRunningLabel.stringValue = booleanToString(bool: device.isRunning())
        deviceIsRunningSomewhereLabel.stringValue = booleanToString(bool: device.isRunningSomewhere())
    }

    fileprivate func populateNominalSampleRatesPopUpButton(device: AudioDevice) {
        deviceNominalSampleRatesPopupButton.removeAllItems()

        if let sampleRates = device.nominalSampleRates(), !sampleRates.isEmpty {
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

    fileprivate func populateClockSourcesPopUpButton(device: AudioDevice) {
        deviceClockSourcesPopupButton.removeAllItems()

        if let clockSourceIDs = device.clockSourceIDs(), !clockSourceIDs.isEmpty {
            deviceClockSourcesPopupButton.isEnabled = true
            for clockSourceID in clockSourceIDs {
                let clockSourceName = device.clockSourceName(clockSourceID: clockSourceID) ?? "Internal"
                deviceClockSourcesPopupButton.addItem(withTitle: clockSourceName)
                deviceClockSourcesPopupButton.lastItem?.tag = Int(clockSourceID)
            }

            if let clockSourceID = device.clockSourceID() {
                deviceClockSourcesPopupButton.selectItem(withTag: Int(clockSourceID))
            }
        } else {
            deviceClockSourcesPopupButton.addItem(withTitle: unsupportedValue)
            deviceClockSourcesPopupButton.isEnabled = false
        }
    }

    fileprivate func populatePlaybackStreamPopUpButton(device: AudioDevice) {
        playbackStreamPopUpButton.removeAllItems()

        if let playbackStreams = device.streams(direction: .playback), !playbackStreams.isEmpty {
            playbackStreamPopUpButton.isEnabled = true
            for stream in playbackStreams {
                playbackStreamPopUpButton.addItem(withTitle: stream.name ?? "Output Stream \(format(id: stream.id))")
                playbackStreamPopUpButton.lastItem?.tag = Int(stream.id)
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

    fileprivate func populateRecordingStreamPopUpButton(device: AudioDevice) {
        recordingStreamPopUpButton.removeAllItems()

        if let recordingStreams = device.streams(direction: .recording), !recordingStreams.isEmpty {
            recordingStreamPopUpButton.isEnabled = true
            for stream in recordingStreams {
                recordingStreamPopUpButton.addItem(withTitle: stream.name ?? "Input Stream \(format(id: stream.id))")
                recordingStreamPopUpButton.lastItem?.tag = Int(stream.id)
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

    fileprivate func populatePlaybackStreamInfo(stream: AudioStream?) {
        playbackStreamVirtualFormatPopUpButton.removeAllItems()
        playbackStreamPhysicalFormatPopUpButton.removeAllItems()

        if let stream = stream {
            playbackStreamIDLabel.stringValue = format(id: stream.id)
            playbackStreamStartingChannelLabel.stringValue = "\(stream.startingChannel ?? 0)"
            playbackStreamTerminalTypeLabel.stringValue = "\(stream.terminalType)"

            if let virtualFormats = stream.availableVirtualFormatsMatchingCurrentNominalSampleRate(), !virtualFormats.isEmpty {
                playbackStreamVirtualFormatPopUpButton.isEnabled = true
                for format in virtualFormats {
                    playbackStreamVirtualFormatPopUpButton.addItem(withTitle: "\(humanReadableStreamBasicDescription(asbd: format))")
                    playbackStreamVirtualFormatPopUpButton.lastItem?.tag = Int(stream.id)
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

            if let physicalFormats = stream.availablePhysicalFormatsMatchingCurrentNominalSampleRate(), !physicalFormats.isEmpty {
                playbackStreamPhysicalFormatPopUpButton.isEnabled = true
                for format in physicalFormats {
                    playbackStreamPhysicalFormatPopUpButton.addItem(withTitle: "\(humanReadableStreamBasicDescription(asbd: format))")
                    playbackStreamPhysicalFormatPopUpButton.lastItem?.tag = Int(stream.id)
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

    fileprivate func populateRecordingStreamInfo(stream: AudioStream?) {
        recordingStreamVirtualFormatPopUpButton.removeAllItems()
        recordingStreamPhysicalFormatPopUpButton.removeAllItems()

        if let stream = stream {
            recordingStreamIDLabel.stringValue = format(id: stream.id)
            recordingStreamStartingChannelLabel.stringValue = "\(stream.startingChannel ?? 0)"
            recordingStreamTerminalTypeLabel.stringValue = "\(stream.terminalType)"

            if let virtualFormats = stream.availableVirtualFormatsMatchingCurrentNominalSampleRate(), !virtualFormats.isEmpty {
                recordingStreamVirtualFormatPopUpButton.isEnabled = true
                for format in virtualFormats {
                    recordingStreamVirtualFormatPopUpButton.addItem(withTitle: "\(humanReadableStreamBasicDescription(asbd: format))")
                    recordingStreamVirtualFormatPopUpButton.lastItem?.tag = Int(stream.id)
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

            if let physicalFormats = stream.availablePhysicalFormatsMatchingCurrentNominalSampleRate(), !physicalFormats.isEmpty {
                recordingStreamPhysicalFormatPopUpButton.isEnabled = true
                for format in physicalFormats {
                    recordingStreamPhysicalFormatPopUpButton.addItem(withTitle: "\(humanReadableStreamBasicDescription(asbd: format))")
                    recordingStreamPhysicalFormatPopUpButton.lastItem?.tag = Int(stream.id)
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

extension ViewController: EventSubscriber {
    func eventReceiver(_ event: Event) {
        switch event {
        case let event as AudioDeviceEvent:
            switch event {
            case let .nominalSampleRateDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
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
            case let .availableNominalSampleRatesDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    populateNominalSampleRatesPopUpButton(device: audioDevice)
                    populateRecordingStreamPopUpButton(device: audioDevice)
                    populatePlaybackStreamPopUpButton(device: audioDevice)
                }
            case let .clockSourceDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    if let clockSourceID = audioDevice.clockSourceID() {
                        deviceClockSourcesPopupButton.selectItem(withTag: Int(clockSourceID))
                    }
                }
            case let .nameDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    deviceNameLabel.stringValue = audioDevice.name
                }

                if let item = deviceListPopUpButton.item(withTag: Int(audioDevice.id)) {
                    item.title = audioDevice.name
                }
            case let .listDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    populateDeviceInformation(device: audioDevice)
                }
            case .volumeDidChange:
                break
            case .muteDidChange:
                break
            case let .isAliveDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    deviceIsAliveLabel.stringValue = booleanToString(bool: audioDevice.isAlive())
                }
            case let .isRunningDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    deviceIsRunningLabel.stringValue = booleanToString(bool: audioDevice.isRunning())
                }
            case let .isRunningSomewhereDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    deviceIsRunningSomewhereLabel.stringValue = booleanToString(bool: audioDevice.isRunningSomewhere())
                }
            case let .hogModeDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    if let hogPID = audioDevice.hogModePID() {
                        deviceHogModeLabel.stringValue = "\(hogPID)"
                    } else {
                        deviceHogModeLabel.stringValue = unknownValue
                    }
                }
            default:
                break
            }
        case let event as AudioHardwareEvent:
            switch event {
            case .deviceListChanged:
                self.populateDeviceList()
            case let .defaultInputDeviceChanged(audioDevice):
                print("Default input device changed to \(audioDevice)")
            case let .defaultOutputDeviceChanged(audioDevice):
                print("Default output device changed to \(audioDevice)")
            case let .defaultSystemOutputDeviceChanged(audioDevice):
                print("Default system output device changed to \(audioDevice)")
            }
        case let event as AudioStreamEvent:
            switch event {
            case let .isActiveDidChange(audioStream):
                print("Audio stream \(audioStream) active status changed to \(audioStream.active)")
            case let .physicalFormatDidChange(audioStream):
                if audioStream.owningDevice == representedObject as? AudioDevice {
                    switch audioStream.direction {
                    case .some(.playback):
                        populatePlaybackStreamInfo(stream: audioStream)
                    case .some(.recording):
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
