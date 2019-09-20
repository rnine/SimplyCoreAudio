//
//  RecordingViewController.swift
//  AMCoreAudio Demo
//
//  Created by Ruben Nine on 03/11/2016.
//  Copyright © 2016 9Labs. All rights reserved.
//

import AMCoreAudio
import Cocoa

extension NSUserInterfaceItemIdentifier {
    static let volumeLabel = NSUserInterfaceItemIdentifier(rawValue: "volumeLabel")
    static let volume = NSUserInterfaceItemIdentifier(rawValue: "volume")
    static let mute = NSUserInterfaceItemIdentifier(rawValue: "mute")
}

class ExtraViewController: NSViewController {
    @IBOutlet var isConnectedLabel: NSTextField!
    @IBOutlet var shouldOwniSubCheckbox: NSButton!
    @IBOutlet var LFEMuteCheckbox: NSButton!
    @IBOutlet var LFEVolumeLabel: NSTextField!
    @IBOutlet var LFEVolumeSlider: NSSlider!
    @IBOutlet var virtualMasterVolumeSlider: NSSlider!
    @IBOutlet var virtualMasterBalanceSlider: NSSlider!
    @IBOutlet var preferredStereoPairLPopUpButton: NSPopUpButton!
    @IBOutlet var preferredStereoPairRPopUpButton: NSPopUpButton!
    @IBOutlet var tableView: NSTableView!

    var representedDirection: AMCoreAudio.Direction?

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            if let audioDevice = representedObject as? AudioDevice {
                populateInfoFields(device: audioDevice)
                tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        if let p = parent as? ViewController {
            representedObject = p.representedObject
        }
    }

    deinit {
        NotificationCenter.defaultCenter.unsubscribe(self, eventType: AudioDeviceEvent.self)
    }

    // MARK: - Actions

    @IBAction func setShouldOwniSub(_ sender: AnyObject) {
        guard let button = sender as? NSButton else { return }

        if let audioDevice = representedObject as? AudioDevice {
            audioDevice.shouldOwniSub = button.state == .on
        }
    }

    @IBAction func setLFEVolume(_ sender: AnyObject) {
        guard let slider = sender as? NSSlider else { return }

        if let audioDevice = representedObject as? AudioDevice {
            audioDevice.lfeVolume = slider.floatValue
        }
    }

    @IBAction func setLFEMute(_ sender: AnyObject) {
        guard let button = sender as? NSButton else { return }

        if let audioDevice = representedObject as? AudioDevice {
            audioDevice.lfeMute = button.state == .on
        }
    }

    @IBAction func setVirtualMasterVolume(_ sender: AnyObject) {
        guard let slider = sender as? NSSlider else { return }

        if let audioDevice = representedObject as? AudioDevice, let direction = representedDirection {
            if audioDevice.setVirtualMasterVolume(slider.floatValue, direction: direction) == false {
                print("Unable to set virtual master volume to \(slider.floatValue) for direction \(direction)")
            }
        }
    }

    @IBAction func setVirtualMasterBalance(_ sender: AnyObject) {
        guard let slider = sender as? NSSlider else { return }

        if let audioDevice = representedObject as? AudioDevice, let direction = representedDirection {
            if audioDevice.setVirtualMasterBalance(slider.floatValue, direction: direction) == false {
                print("Unable to set virtual master balance to \(slider.floatValue) for direction \(direction)")
            }
        }
    }

    @IBAction func setPreferredStereoPairL(_ sender: AnyObject) {
        guard let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem else {
            return
        }

        if let audioDevice = representedObject as? AudioDevice, let direction = representedDirection {
            if let preferredChannelsForStereo = audioDevice.preferredChannelsForStereo(direction: direction) {
                var newPair = preferredChannelsForStereo
                newPair.left = UInt32(item.tag)

                if audioDevice.setPreferredChannelsForStereo(channels: newPair, direction: direction) == false {
                    print("Unable to set preferred channels for stereo to \(newPair) for direction \(direction).")
                }
            }
        }
    }

    @IBAction func setPreferredStereoPairR(_ sender: AnyObject) {
        guard let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem else {
            return
        }

        if let audioDevice = representedObject as? AudioDevice, let direction = representedDirection {
            if let preferredChannelsForStereo = audioDevice.preferredChannelsForStereo(direction: direction) {
                var newPair = preferredChannelsForStereo
                newPair.right = UInt32(item.tag)

                if audioDevice.setPreferredChannelsForStereo(channels: newPair, direction: direction) == false {
                    print("Unable to set preferred channels for stereo to \(newPair) for direction \(direction).")
                }
            }
        }
    }

    @IBAction func setChannelMuteState(_ sender: AnyObject) {
        guard let button = sender as? NSButton else { return }

        if let device = representedObject as? AudioDevice, let direction = representedDirection {
            let channel = UInt32(button.tag)

            if device.setMute(button.state == .on, channel: channel, direction: direction) == false {
                print("Unable to update mute state for channel \(channel) and direction \(direction)")
            }
        }
    }

    @IBAction func setChannelVolume(_ sender: AnyObject) {
        guard let slider = sender as? NSSlider else { return }

        if let device = representedObject as? AudioDevice, let direction = representedDirection {
            let channel = UInt32(slider.tag)

            if device.setVolume(slider.floatValue, channel: channel, direction: direction) == false {
                print("Unable to update volume for channel \(channel) and direction \(direction)")
            }
        }
    }

    // MARK: - Private

    fileprivate func populateInfoFields(device: AudioDevice) {
        guard let direction = representedDirection else { return }

        populatePreferredStereoPair(device: device)

        if let isJackConnected = device.isJackConnected(direction: direction) {
            isConnectedLabel.stringValue = isJackConnected ? "Yes" : "No"
        } else {
            isConnectedLabel.stringValue = "N/A"
        }

        if let virtualMasterVolume = device.virtualMasterVolume(direction: direction) {
            virtualMasterVolumeSlider.floatValue = virtualMasterVolume
            virtualMasterVolumeSlider.isEnabled = true
        } else {
            virtualMasterVolumeSlider.isEnabled = false
        }

        if let virtualMasterBalance = device.virtualMasterBalance(direction: direction) {
            virtualMasterBalanceSlider.floatValue = virtualMasterBalance
            virtualMasterBalanceSlider.isEnabled = true
        } else {
            virtualMasterBalanceSlider.isEnabled = false
        }

        switch direction {
        case .recording:
            shouldOwniSubCheckbox.isHidden = true
            LFEVolumeLabel.isHidden = true
            LFEVolumeSlider.isHidden = true
            LFEMuteCheckbox.isHidden = true
        case .playback:
            shouldOwniSubCheckbox.isHidden = false
            LFEVolumeLabel.isHidden = false
            LFEVolumeSlider.isHidden = false
            LFEMuteCheckbox.isHidden = false

            if let shouldOwniSub = device.shouldOwniSub {
                shouldOwniSubCheckbox.state = shouldOwniSub ? .on : .off
                shouldOwniSubCheckbox.isEnabled = true
            } else {
                shouldOwniSubCheckbox.state = .off
                shouldOwniSubCheckbox.isEnabled = false
            }

            if let LFEVolume = device.lfeVolume {
                LFEVolumeSlider.floatValue = LFEVolume
                LFEVolumeSlider.isEnabled = true
            } else {
                LFEVolumeSlider.isEnabled = false
            }

            if let LFEMute = device.lfeMute {
                LFEMuteCheckbox.state = LFEMute == true ? .on : .off
                LFEMuteCheckbox.isEnabled = true
            } else {
                LFEMuteCheckbox.state = .off
                LFEMuteCheckbox.isEnabled = false
            }
        }
    }

    fileprivate func populatePreferredStereoPair(device: AudioDevice) {
        guard let direction = representedDirection else { return }

        preferredStereoPairLPopUpButton.removeAllItems()
        preferredStereoPairRPopUpButton.removeAllItems()

        let channels = device.channels(direction: direction)

        if let preferredChannelsForStereo = device.preferredChannelsForStereo(direction: direction), channels > 0 {
            preferredStereoPairLPopUpButton.isEnabled = true
            preferredStereoPairRPopUpButton.isEnabled = true

            for channel in 1...device.channels(direction: direction) {
                let channelName = String(channel)
                preferredStereoPairLPopUpButton.addItem(withTitle: channelName)
                preferredStereoPairLPopUpButton.lastItem?.tag = Int(channel)
                preferredStereoPairRPopUpButton.addItem(withTitle: channelName)
                preferredStereoPairRPopUpButton.lastItem?.tag = Int(channel)
            }

            preferredStereoPairLPopUpButton.selectItem(withTag: Int(preferredChannelsForStereo.left))
            preferredStereoPairRPopUpButton.selectItem(withTag: Int(preferredChannelsForStereo.right))
        } else {
            preferredStereoPairLPopUpButton.isEnabled = false
            preferredStereoPairRPopUpButton.isEnabled = false
        }
    }
}

// MARK: - NSTableViewDelegate Functions

extension ExtraViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }

        switch tableColumn.identifier.rawValue {
        case "channel":
            let cellView = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView

            if let textField = cellView?.textField {
                textField.stringValue = row == 0 ? "M" : String(row)
            }

            return cellView
        case "name":
            let cellView = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView

            if let textField = cellView?.textField {
                if let device = representedObject as? AudioDevice, let direction = representedDirection,
                    let channelName = device.name(channel: UInt32(row), direction: direction) {
                    textField.stringValue = channelName
                } else {
                    textField.stringValue = row == 0 ? "Master" : "Channel \(row)"
                }
            }

            return cellView
        case "mute":
            let cellView = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? CheckBoxCellView

            if let checkBoxButton = cellView?.checkBoxButton {
                checkBoxButton.title = ""

                if let device = representedObject as? AudioDevice, let direction = representedDirection {
                    if let isMuted = device.isMuted(channel: UInt32(row), direction: direction) {
                        checkBoxButton.state = isMuted ? .on : .off
                        checkBoxButton.isEnabled = true
                        checkBoxButton.tag = row
                        checkBoxButton.action = #selector(setChannelMuteState)
                        checkBoxButton.target = self
                    } else {
                        checkBoxButton.state = .off
                        checkBoxButton.isEnabled = false
                        checkBoxButton.action = nil
                        checkBoxButton.target = nil
                    }
                }
            }

            return cellView
        case "volumeLabel":
            let cellView = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView

            if let textField = cellView?.textField {
                if let device = representedObject as? AudioDevice, let direction = representedDirection {
                    if let volume = device.volumeInDecibels(channel: UInt32(row), direction: direction) {
                        textField.stringValue = String(volume)
                        textField.isEnabled = true
                    } else {
                        textField.stringValue = "N/A"
                        textField.isEnabled = false
                    }
                }
            }

            return cellView
        case "volume":
            let cellView = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? SliderCellView

            if let slider = cellView?.slider {
                if let device = representedObject as? AudioDevice, let direction = representedDirection {
                    if let volume = device.volume(channel: UInt32(row), direction: direction) {
                        slider.floatValue = volume
                        slider.isEnabled = true
                        slider.tag = row
                        slider.action = #selector(setChannelVolume)
                        slider.target = self
                    } else {
                        slider.floatValue = 1.0
                        slider.isEnabled = false
                        slider.action = nil
                        slider.target = nil
                    }
                }
            }

            return cellView
        default:
            return nil
        }
    }

    func tableView(_: NSTableView, shouldReorderColumn _: Int, toColumn _: Int) -> Bool {
        return false
    }

    func tableView(_: NSTableView, shouldTypeSelectFor _: NSEvent, withCurrentSearch _: String?) -> Bool {
        return false
    }
}

// MARK: - NSTableViewDataSource Functions

extension ExtraViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        if let device = representedObject as? AudioDevice, let direction = representedDirection {
            let channels = device.channels(direction: direction)

            if channels > 0 {
                return Int(channels) + 1 // take master channel into account
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
}

extension ExtraViewController: EventSubscriber {
    func eventReceiver(_ event: Event) {
        switch event {
        case let event as AudioDeviceEvent:
            switch event {
            case let .isJackConnectedDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    populateInfoFields(device: audioDevice)
                }
            case .volumeDidChange(let audioDevice, let channel, _):
                if representedObject as? AudioDevice == audioDevice {
                    populateInfoFields(device: audioDevice)

                    let volumeIndices = IndexSet([tableView.column(withIdentifier: .volumeLabel),
                                                  tableView.column(withIdentifier: .volume)])

                    tableView.reloadData(forRowIndexes: IndexSet(integer: Int(channel)),
                                         columnIndexes: volumeIndices)
                }
            case .muteDidChange(let audioDevice, let channel, _):
                if representedObject as? AudioDevice == audioDevice {
                    populateInfoFields(device: audioDevice)

                    let muteIndex = IndexSet([tableView.column(withIdentifier: .mute)])

                    tableView.reloadData(forRowIndexes: IndexSet(integer: Int(channel)),
                                         columnIndexes: muteIndex)
                }
            case let .preferredChannelsForStereoDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    populatePreferredStereoPair(device: audioDevice)
                }
            case let .listDidChange(audioDevice):
                if representedObject as? AudioDevice == audioDevice {
                    populatePreferredStereoPair(device: audioDevice)
                    tableView.reloadData()
                }
            default:
                break
            }
        default:
            break
        }
    }
}
