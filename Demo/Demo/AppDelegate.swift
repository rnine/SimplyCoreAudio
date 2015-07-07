//
//  AppDelegate.swift
//  Demo
//
//  Created by Ruben on 7/7/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Cocoa
import AMCoreAudio

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    private let audioDeviceManager = AMCoreAudioManager.sharedManager()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        audioDeviceManager.delegate = self

        print("Known devices: \(audioDeviceManager.allKnownDevices)")
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

// MARK: - AMCoreAudioManagerDelegate Methods
extension AppDelegate : AMCoreAudioManagerDelegate {

    func hardwareDeviceListChangedWithAddedDevices(addedDevices: Set<NSObject>!, andRemovedDevices removedDevices: Set<NSObject>!) {
        print("Devices added: \(addedDevices)")
        print("Devices removed: \(removedDevices)")
    }

    func hardwareDefaultInputDeviceChangedTo(audioDevice: AMCoreAudioDevice!) {
        print("Default input device changed to \(audioDevice)")
    }

    func hardwareDefaultOutputDeviceChangedTo(audioDevice: AMCoreAudioDevice!) {
        print("Default output device changed to \(audioDevice)")
    }

    func hardwareDefaultSystemDeviceChangedTo(audioDevice: AMCoreAudioDevice!) {
        print("System output device changed to \(audioDevice)")
    }

    func audioDeviceListDidChange(audioDevice: AMCoreAudioDevice!) {
        print("\(audioDevice) owned devices list changed")
    }

    func audioDeviceNominalSampleRateDidChange(audioDevice: AMCoreAudioDevice!) {
        print("\(audioDevice) sample rate changed to \(audioDevice.nominalSampleRate())")
    }

    func audioDeviceVolumeDidChange(audioDevice: AMCoreAudioDevice!, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection) {
        let newVolume = audioDevice.volumeInDecibelsForChannel(channel, andDirection: direction)
        print("\(audioDevice) volume for channel \(channel) and direction \(direction) changed to \(newVolume)dbFS")
    }

    func audioDeviceMuteDidChange(audioDevice: AMCoreAudioDevice!, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection) {
        let isMuted = audioDevice.isChannelMuted(channel, andDirection: direction)
        print("\(audioDevice) mute for channel \(channel) and direction \(direction) changed to \(isMuted)")
    }

    func audioDeviceClockSourceDidChange(audioDevice: AMCoreAudioDevice!, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection) {
        let clockSourceName = audioDevice.clockSourceForChannel(channel, andDirection: direction)
        print("\(audioDevice) clock source changed to \(clockSourceName)")
    }

    func audioDeviceNameDidChange(audioDevice: AMCoreAudioDevice!) {
        print("\(audioDevice) name changed to \(audioDevice.deviceName())")
    }

    func audioDeviceAvailableNominalSampleRatesDidChange(audioDevice: AMCoreAudioDevice!) {
        print("\(audioDevice) nominal sample rates changed to \(audioDevice.nominalSampleRates)")
    }

    func audioDeviceIsAliveDidChange(audioDevice: AMCoreAudioDevice!) {
        print("\(audioDevice) 'is alive' changed to \(audioDevice.isAlive())")
    }

    func audioDeviceIsRunningDidChange(audioDevice: AMCoreAudioDevice!) {
        print("\(audioDevice) 'is running' changed to \(audioDevice.isRunning())")
    }

    func audioDeviceIsRunningSomewhereDidChange(audioDevice: AMCoreAudioDevice!) {
        print("\(audioDevice) 'is running somewhere' changed to \(audioDevice.isRunningSomewhere())")
    }
}
