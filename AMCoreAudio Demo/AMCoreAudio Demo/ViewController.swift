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
    @IBOutlet var devicePlaybackLatencyLabel: NSTextField!
    @IBOutlet var deviceRecordingLatencyLabel: NSTextField!
    @IBOutlet var devicePlaybackSafetyOffsetLabel: NSTextField!
    @IBOutlet var deviceRecordingSafetyOffsetLabel: NSTextField!
    @IBOutlet var devicePlaybackMasterVolumeLabel: NSTextField!
    @IBOutlet var deviceRecordingMasterVolumeLabel: NSTextField!
    @IBOutlet var deviceHogPIDLabel: NSTextField!

    fileprivate let unknownValue = "<Unknown>"

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            if let audioDevice = representedObject as? AMAudioDevice {
                populateDeviceInformation(device: audioDevice)
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
            deviceHogPIDLabel.stringValue = "\(hogPID)"
        } else {
            deviceHogPIDLabel.stringValue = unknownValue
        }
    }

    fileprivate func populateNominalSampleRatesPopUpButton(device: AMAudioDevice) {
        deviceNominalSampleRatesPopupButton.removeAllItems()

        if let sampleRates = device.nominalSampleRates() {
            deviceNominalSampleRatesPopupButton.isEnabled = true
            for sampleRate in sampleRates {
                deviceNominalSampleRatesPopupButton.addItem(withTitle: format(sampleRate: sampleRate))
                deviceNominalSampleRatesPopupButton.lastItem?.representedObject = sampleRate
            }

            if let nominalSampleRate = device.nominalSampleRate() {
                deviceNominalSampleRatesPopupButton.selectItem(withRepresentedObject: nominalSampleRate)
            }
        }

        if deviceNominalSampleRatesPopupButton.itemArray.count == 0 {
            deviceNominalSampleRatesPopupButton.addItem(withTitle: "None supported")
            deviceNominalSampleRatesPopupButton.isEnabled = false
        }
    }

    fileprivate func populatePlaybackMasterVolume(device: AMAudioDevice) {
        if let playbackMasterVolume = device.masterVolumeInDecibelsForDirection(.Playback) {
            let isMuted = (device.isMasterVolumeMutedForDirection(.Playback) ?? false)
            devicePlaybackMasterVolumeLabel.isEnabled = true
            devicePlaybackMasterVolumeLabel.stringValue = isMuted ? "Muted" : "\(playbackMasterVolume) dBfs"
        } else {
            devicePlaybackMasterVolumeLabel.isEnabled = false
        }
    }

    fileprivate func populateRecordingMasterVolume(device: AMAudioDevice) {
        if let recordingMasterVolume = device.masterVolumeInDecibelsForDirection(.Recording) {
            let isMuted = (device.isMasterVolumeMutedForDirection(.Recording) ?? false)
            deviceRecordingMasterVolumeLabel.isEnabled = true
            deviceRecordingMasterVolumeLabel.stringValue = isMuted ? "Muted" : "\(recordingMasterVolume) dBfs"
        } else {
            deviceRecordingMasterVolumeLabel.isEnabled = false
        }
    }

    fileprivate func booleanToString(bool: Bool) -> String {
        return bool == true ? "Yes" : "No"
    }

    fileprivate func format(sampleRate: Float64) -> String {
        return String.init(format: "%.1f kHz", sampleRate / 1000)
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
                }
            case .availableNominalSampleRatesDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    populateNominalSampleRatesPopUpButton(device: audioDevice)
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
                print("\(audioDevice) 'is alive' changed to \(audioDevice.isAlive())")
            case .isRunningDidChange(let audioDevice):
                print("\(audioDevice) 'is running' changed to \(audioDevice.isRunning())")
            case .isRunningSomewhereDidChange(let audioDevice):
                print("\(audioDevice) 'is running somewhere' changed to \(audioDevice.isRunningSomewhere())")
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
                print("is active did change in \(audioStream)")
            case .physicalFormatDidChange(let audioStream):
                print("physical format did change in \(audioStream.streamID), owner: \(audioStream.owningDevice), format: \(audioStream.physicalFormat)")
            }
        default:
            break
        }
    }
}
