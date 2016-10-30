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
    @IBOutlet var deviceNominalSampleRateLabel: NSTextField!
    @IBOutlet var deviceActualSampleRateLabel: NSTextField!
    @IBOutlet var devicePlaybackLatencyLabel: NSTextField!
    @IBOutlet var deviceRecordingLatencyLabel: NSTextField!
    @IBOutlet var devicePlaybackSafetyOffsetLabel: NSTextField!
    @IBOutlet var deviceRecordingSafetyOffsetLabel: NSTextField!
    @IBOutlet var devicePlaybackMasterVolumeLabel: NSTextField!
    @IBOutlet var deviceRecordingMasterVolumeLabel: NSTextField!
    @IBOutlet var deviceHogPIDLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Subscribe to events

        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioHardwareEvent.self, dispatchQueue: DispatchQueue.main)
        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioStreamEvent.self, dispatchQueue: DispatchQueue.main)

        // Populate device list
        populateDeviceList()

        if let selectedItem = deviceListPopUpButton.selectedItem {
            let deviceID = AudioObjectID(selectedItem.tag)

            if let device = AMAudioDevice.lookupByID(deviceID) {
                populateDeviceInformation(device: device)
            }
        }
    }

    deinit {
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioHardwareEvent.self)
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioDeviceEvent.self)
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioStreamEvent.self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: - Actions

    @IBAction func showDevice(_ sender: AnyObject) {
        if let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem {
            let deviceID = AudioObjectID(item.tag)

            if let device = AMAudioDevice.lookupByID(deviceID) {
                populateDeviceInformation(device: device)
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
    }

    fileprivate func populateDeviceInformation(device: AMAudioDevice) {
        let unknownValue = "<Unknown>"

        deviceNameLabel.stringValue = device.deviceName()
        deviceManufacturerLabel.stringValue = device.deviceManufacturer() ?? unknownValue
        deviceIDLabel.stringValue = "\(device.deviceID)"
        deviceUIDLabel.stringValue = device.deviceUID()!
        deviceModelUIDLabel.stringValue = device.deviceModelUID() ?? unknownValue
        deviceIsHiddenLabel.stringValue = booleanToString(bool: device.deviceIsHidden())
        deviceTransportTypeLabel.stringValue = device.transportType()?.rawValue ?? unknownValue
        deviceConfigAppLabel.stringValue = device.deviceConfigurationApplication() ?? unknownValue

        deviceNominalSampleRatesPopupButton.removeAllItems()

        if let sampleRates = device.nominalSampleRates() {
            deviceNominalSampleRatesPopupButton.isEnabled = true
            for sampleRate in sampleRates {
                deviceNominalSampleRatesPopupButton.addItem(withTitle: format(sampleRate: sampleRate))
            }
        }

        if deviceNominalSampleRatesPopupButton.itemArray.count == 0 {
            deviceNominalSampleRatesPopupButton.addItem(withTitle: "None supported")
            deviceNominalSampleRatesPopupButton.isEnabled = false
        }

        if let nominalSampleRate = device.nominalSampleRate() {
            deviceNominalSampleRateLabel.stringValue = format(sampleRate: nominalSampleRate)
        } else {
            deviceActualSampleRateLabel.stringValue = unknownValue
        }

        if let actualSampleRate = device.actualSampleRate() {
            deviceActualSampleRateLabel.stringValue = format(sampleRate: actualSampleRate)
        } else {
            deviceActualSampleRateLabel.stringValue = unknownValue
        }

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

        if let playbackMasterVolume = device.masterVolumeInDecibelsForDirection(.Playback) {
            devicePlaybackMasterVolumeLabel.isEnabled = true
            devicePlaybackMasterVolumeLabel.stringValue = "\(playbackMasterVolume) dBfs"
        } else {
            devicePlaybackMasterVolumeLabel.isEnabled = false
        }

        if let recordingMasterVolume = device.masterVolumeInDecibelsForDirection(.Recording) {
            deviceRecordingMasterVolumeLabel.isEnabled = true
            deviceRecordingMasterVolumeLabel.stringValue = "\(recordingMasterVolume) dBfs"
        } else {
            deviceRecordingMasterVolumeLabel.isEnabled = false
        }

        if let hogPID = device.hogModePID() {
            deviceHogPIDLabel.stringValue = "\(hogPID)"
        } else {
            deviceHogPIDLabel.stringValue = unknownValue
        }
    }

    private func booleanToString(bool: Bool) -> String {
        return bool == true ? "Yes" : "No"
    }

    private func format(sampleRate: Float64) -> String {
        return String.init(format: "%.1f kHz", sampleRate / 1000)
    }
}

extension ViewController : AMEventSubscriber {

    func eventReceiver(_ event: AMEvent) {
        switch event {
        case let event as AMAudioDeviceEvent:
            switch event {
            case .nominalSampleRateDidChange(let audioDevice):
                if let sampleRate = audioDevice.nominalSampleRate() {
                    print("\(audioDevice) sample rate changed to \(sampleRate)")
                }
            case .availableNominalSampleRatesDidChange(let audioDevice):
                if let nominalSampleRates = audioDevice.nominalSampleRates() {
                    print("\(audioDevice) nominal sample rates changed to \(nominalSampleRates)")
                }
            case .clockSourceDidChange(let audioDevice, let channel, let direction):
                if let clockSourceName = audioDevice.clockSourceForChannel(channel, andDirection: direction) {
                    print("\(audioDevice) clock source changed to \(clockSourceName)")
                }
            case .nameDidChange(let audioDevice):
                print("\(audioDevice) name changed to \(audioDevice.deviceName())")
            case .listDidChange(let audioDevice):
                print("\(audioDevice) owned devices list changed")
            case .volumeDidChange(let audioDevice, let channel, let direction):
                if let newVolume = audioDevice.volumeInDecibelsForChannel(channel, andDirection: direction) {
                    print("\(audioDevice) volume for channel \(channel) and direction \(direction) changed to \(newVolume)dbFS")
                }
            case .muteDidChange(let audioDevice, let channel, let direction):
                if let isMuted = audioDevice.isChannelMuted(channel, andDirection: direction) {
                    print("\(audioDevice) mute for channel \(channel) and direction \(direction) changed to \(isMuted)")
                }
            case .isAliveDidChange(let audioDevice):
                print("\(audioDevice) 'is alive' changed to \(audioDevice.isAlive())")
            case .isRunningDidChange(let audioDevice):
                print("\(audioDevice) 'is running' changed to \(audioDevice.isRunning())")
            case .isRunningSomewhereDidChange(let audioDevice):
                print("\(audioDevice) 'is running somewhere' changed to \(audioDevice.isRunningSomewhere())")
            }
        case let event as AMAudioHardwareEvent:
            switch event {
            case .deviceListChanged(let addedDevices, let removedDevices):
                print("Devices added: \(addedDevices)")
                print("Devices removed: \(removedDevices)")
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
                print("is active did change in \(audioStream)")
            case .physicalFormatDidChange(let audioStream):
                print("physical format did change in \(audioStream.streamID), owner: \(audioStream.owningDevice), format: \(audioStream.physicalFormat)")
            }
        default:
            break
        }
    }
}
