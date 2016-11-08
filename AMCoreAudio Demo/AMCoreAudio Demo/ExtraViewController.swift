//
//  RecordingViewController.swift
//  AMCoreAudio Demo
//
//  Created by Ruben Nine on 03/11/2016.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Cocoa
import AMCoreAudio

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

    var representedDirection: AMCoreAudio.Direction?

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            if let audioDevice = representedObject as? AMAudioDevice {
                populateInfoFields(device: audioDevice)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
    }

    
    override func viewWillAppear() {
        super.viewWillAppear()

        if let p = parent as? ViewController {
            representedObject = p.representedObject
        }
    }


    deinit {
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioDeviceEvent.self)
    }

    // MARK: - Actions

    @IBAction func setShouldOwniSub(_ sender: AnyObject) {
        guard let button = sender as? NSButton else { return }

        if let audioDevice = representedObject as? AMAudioDevice {
            audioDevice.shouldOwniSub = button.state == NSOnState
        }
    }

    @IBAction func setLFEVolume(_ sender: AnyObject) {
        guard let slider = sender as? NSSlider else { return }

        if let audioDevice = representedObject as? AMAudioDevice {
            audioDevice.LFEVolume = slider.floatValue
        }
    }

    @IBAction func setLFEMute(_ sender: AnyObject) {
        guard let button = sender as? NSButton else { return }

        if let audioDevice = representedObject as? AMAudioDevice {
            audioDevice.LFEMute = button.state == NSOnState
        }
    }

    @IBAction func setVirtualMasterVolume(_ sender: AnyObject) {
        guard let slider = sender as? NSSlider else { return }

        if let audioDevice = representedObject as? AMAudioDevice, let direction = representedDirection {
            if audioDevice.setVirtualMasterVolume(slider.floatValue, direction: direction) == false {
                print("Unable to set virtual master volume to \(slider.floatValue) for direction \(direction)")
            }
        }
    }

    @IBAction func setVirtualMasterBalance(_ sender: AnyObject) {
        guard let slider = sender as? NSSlider else { return }

        if let audioDevice = representedObject as? AMAudioDevice, let direction = representedDirection {
            if audioDevice.setVirtualMasterBalance(slider.floatValue, direction: direction) == false {
                print("Unable to set virtual master balance to \(slider.floatValue) for direction \(direction)")
            }
        }
    }

    @IBAction func setPreferredStereoPairL(_ sender: AnyObject) {
        guard let popUpButton = sender as? NSPopUpButton, let item = popUpButton.selectedItem else {
            return
        }

        if let audioDevice = representedObject as? AMAudioDevice, let direction = representedDirection {
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

        if let audioDevice = representedObject as? AMAudioDevice, let direction = representedDirection {
            if let preferredChannelsForStereo = audioDevice.preferredChannelsForStereo(direction: direction) {
                var newPair = preferredChannelsForStereo
                newPair.right = UInt32(item.tag)

                if audioDevice.setPreferredChannelsForStereo(channels: newPair, direction: direction) == false {
                    print("Unable to set preferred channels for stereo to \(newPair) for direction \(direction).")
                }
            }
        }
    }

    // MARK: - Private

    fileprivate func populateInfoFields(device: AMAudioDevice) {
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
        case .Recording:
            shouldOwniSubCheckbox.isHidden = true
            LFEVolumeLabel.isHidden = true
            LFEVolumeSlider.isHidden = true
            LFEMuteCheckbox.isHidden = true
        case .Playback:
            shouldOwniSubCheckbox.isHidden = false
            LFEVolumeLabel.isHidden = false
            LFEVolumeSlider.isHidden = false
            LFEMuteCheckbox.isHidden = false

            if let shouldOwniSub = device.shouldOwniSub {
                shouldOwniSubCheckbox.state = shouldOwniSub ? NSOnState : NSOffState
                shouldOwniSubCheckbox.isEnabled = true
            } else {
                shouldOwniSubCheckbox.state = NSOffState
                shouldOwniSubCheckbox.isEnabled = false
            }

            if let LFEVolume = device.LFEVolume {
                LFEVolumeSlider.floatValue = LFEVolume
                LFEVolumeSlider.isEnabled = true
            } else {
                LFEVolumeSlider.isEnabled = false
            }

            if let LFEMute = device.LFEMute {
                LFEMuteCheckbox.state = LFEMute == true ? NSOnState : NSOffState
                LFEMuteCheckbox.isEnabled = true
            } else {
                LFEMuteCheckbox.isEnabled = false
            }
        default:
            break
        }
    }

    fileprivate func populatePreferredStereoPair(device: AMAudioDevice) {
        guard let direction = representedDirection else { return }

        preferredStereoPairLPopUpButton.removeAllItems()
        preferredStereoPairRPopUpButton.removeAllItems()

        let channels = device.channels(direction: direction)

        if let preferredChannelsForStereo = device.preferredChannelsForStereo(direction: direction), channels > 0 {
            preferredStereoPairLPopUpButton.isEnabled = true
            preferredStereoPairRPopUpButton.isEnabled = true

            for channel in 1...device.channels(direction: direction) {
                let channelName = device.name(channel: channel, direction: direction) ?? String(channel)
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

extension ExtraViewController : AMEventSubscriber {

    func eventReceiver(_ event: AMEvent) {
        switch event {
        case let event as AMAudioDeviceEvent:
            switch event {
            case .isJackConnectedDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    populateInfoFields(device: audioDevice)
                }
            case .volumeDidChange(let audioDevice, _, _):
                if representedObject as? AMAudioDevice == audioDevice {
                    populateInfoFields(device: audioDevice)
                }
            case .muteDidChange(let audioDevice, _, _):
                if representedObject as? AMAudioDevice == audioDevice {
                    populateInfoFields(device: audioDevice)
                }
            case .preferredChannelsForStereoDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    populatePreferredStereoPair(device: audioDevice)
                }
            case .listDidChange(let audioDevice):
                if representedObject as? AMAudioDevice == audioDevice {
                    populatePreferredStereoPair(device: audioDevice)
                }
            default:
                break
            }
        default:
            break
        }
    }
}
