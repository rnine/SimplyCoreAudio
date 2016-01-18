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

    private let audioDeviceManager = AMCoreAudioManager.sharedManager

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        audioDeviceManager.delegate = self

        print("+ All known devices: \(audioDeviceManager.allKnownDevices)")

        if let defaultOutputDevice = AMCoreAudioDevice.defaultOutputDevice() {
            print("\n+ Default output device is '\(defaultOutputDevice.deviceName())':")
            printAudioDevice(defaultOutputDevice)
        }

        if let defaultInputDevice = AMCoreAudioDevice.defaultInputDevice() {
            print("\n+ Default input device is '\(defaultInputDevice.deviceName())':")
            printAudioDevice(defaultInputDevice)
        }

        if let defaultSystemOutputDevice = AMCoreAudioDevice.defaultSystemOutputDevice() {
            print("\n+ Default system output device is '\(defaultSystemOutputDevice.deviceName())':")
            printAudioDevice(defaultSystemOutputDevice)
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    private func printAudioDevice(audioDevice: AMCoreAudioDevice) {
        let deviceID = audioDevice.deviceID
        print("|- ID: \(deviceID)")

        if let deviceUID = audioDevice.deviceUID() {
            print("|- UID: \(deviceUID)")
        }

        if let modelUID = audioDevice.deviceModelUID() {
            print("|- Model UID: \(modelUID)")
        }

        if let manufacturer = audioDevice.deviceManufacturer() {
            print("|- Manufacturer: \(manufacturer)")
        }

        if let transportType = audioDevice.transportType() {
            print("|- Transport type: \(transportType)")
        }

        if let configurationApplication = audioDevice.deviceConfigurationApplication() {
            print("|- Configuration application: \(configurationApplication)")
        }

        let deviceIsHidden = audioDevice.deviceIsHidden()
        print("|- Is hidden? \(deviceIsHidden)")

        let playbackDirection = Direction.Playback
        print("|- Preferred stereo channels for \(playbackDirection): \(audioDevice.preferredStereoChannelsForDirection(playbackDirection))")

        let recordingDirection = Direction.Recording
        print("|- Preferred stereo channels for \(recordingDirection): \(audioDevice.preferredStereoChannelsForDirection(recordingDirection))")

        if let nominalSampleRates = audioDevice.nominalSampleRates() {
            print("|- Nominal sample rates: \(nominalSampleRates)")
        }

        if let nominalSampleRate = audioDevice.nominalSampleRate() {
            print("|- Nominal sample rate: \(nominalSampleRate)")
        }

        if let actualSampleRate = audioDevice.actualSampleRate() {
            print("|- Actual sample rate: \(actualSampleRate)")
        }

        if let playbackClockSources = audioDevice.clockSourcesForChannel(0, andDirection: playbackDirection) {
            print("|- Available clock sources for \(playbackDirection): \(playbackClockSources)")
        }

        if let playbackClockSource = audioDevice.clockSourceForChannel(0, andDirection: playbackDirection) {
            print("|- Active clock source for \(playbackDirection): \(playbackClockSource)")
        }

        if let recordingClockSources = audioDevice.clockSourcesForChannel(0, andDirection: recordingDirection) {
            print("|- Available clock sources for \(recordingDirection): \(recordingClockSources)")
        }

        if let recordingClockSource = audioDevice.clockSourceForChannel(0, andDirection: recordingDirection) {
            print("|- Active clock source for \(recordingDirection): \(recordingClockSource)")
        }

        if let playbackLatency = audioDevice.deviceLatencyFramesForDirection(playbackDirection) {
            print("|- \(playbackDirection) latency: \(playbackLatency) frames")
        }

        if let recordingLatency = audioDevice.deviceLatencyFramesForDirection(recordingDirection) {
            print("|- \(recordingDirection) latency: \(recordingLatency) frames")
        }

        if let playbackSafetyOffset = audioDevice.deviceSafetyOffsetFramesForDirection(playbackDirection) {
            print("|- \(playbackDirection) safety offset: \(playbackSafetyOffset) frames")
        }

        if let recordingSafetyOffset = audioDevice.deviceSafetyOffsetFramesForDirection(recordingDirection) {
            print("|- \(recordingDirection) safety offset: \(recordingSafetyOffset) frames")
        }

        let canSetMasterPlaybackVolume = audioDevice.canSetMasterVolumeForDirection(playbackDirection)
        print("|- Can set master \(playbackDirection) volume? \(canSetMasterPlaybackVolume)")

        let canSetMasterRecordingVolume = audioDevice.canSetMasterVolumeForDirection(recordingDirection)
        print("|- Can set master \(recordingDirection) volume? \(canSetMasterRecordingVolume)")

        if let masterPlaybackVolume = audioDevice.masterVolumeInDecibelsForDirection(playbackDirection) {
            print("|- \(playbackDirection) master volume: \(masterPlaybackVolume)dbFS")

            if let masterPlaybackVolumeInfo = audioDevice.volumeInfoForChannel(UInt32(0), andDirection: playbackDirection) {
                print("|  - Volume info: \(masterPlaybackVolumeInfo)")
            }
        }

        if let masterRecordingVolume = audioDevice.masterVolumeInDecibelsForDirection(recordingDirection) {
            print("|- \(recordingDirection) master volume: \(masterRecordingVolume)dbFS")

            if let masterRecordingVolumeInfo = audioDevice.volumeInfoForChannel(UInt32(0), andDirection: recordingDirection) {
                print("|  - Volume info: \(masterRecordingVolumeInfo)")
            }
        }

        if let playbackChannels = audioDevice.channelsForDirection(playbackDirection) {
            print("|- \(playbackDirection) channel count is \(playbackChannels)")

            for channel in 1...playbackChannels {
                if let volume = audioDevice.volumeInDecibelsForChannel(channel, andDirection: playbackDirection) {
                    let nameForChannel = audioDevice.nameForChannel(channel, andDirection: playbackDirection) ?? "<No named>"
                    print("|  - Channel \(channel) (\(nameForChannel)) volume is \(volume)dBFS")

                    if let volumeInfo = audioDevice.volumeInfoForChannel(channel, andDirection: playbackDirection) {
                        print("|    - Volume info: \(volumeInfo)")
                    }
                }
            }
        }

        if let recordingChannels = audioDevice.channelsForDirection(recordingDirection) {
            print("|- \(recordingDirection) channel count is \(recordingChannels)")

            for channel in 1...recordingChannels {
                if let volume = audioDevice.volumeInDecibelsForChannel(channel, andDirection: recordingDirection) {
                    let nameForChannel = audioDevice.nameForChannel(channel, andDirection: recordingDirection) ?? "<No named>"
                    print("|  - Channel \(channel) (\(nameForChannel)) volume is \(volume)dBFS")

                    if let volumeInfo = audioDevice.volumeInfoForChannel(channel, andDirection: recordingDirection) {
                        print("|    - Volume info: \(volumeInfo)")
                    }
                }
            }
        }

        if let relatedDevices = audioDevice.relatedDevices() {
            print("|- Related devices are \(relatedDevices)")
        }

        if let controlList = audioDevice.controlList() {
            print("|- Control list is \(controlList)")
        }

        if let ownedObjectIDs = audioDevice.ownedObjectIDs() {
            print("|- Owned object IDs are \(ownedObjectIDs)")
        }
        
        if let hogModePID = audioDevice.hogModePID() {
            print("|- Hog mode PID is \(hogModePID)")
        }

        print("|")
        print("| (Formatters Extension)")
        print("|")
        print("|- Actual sample rate: \(audioDevice.actualSampleRateFormattedWithShortFormat(true))")
        print("|- Latency: \(audioDevice.latencyDescription())")
        print("|- Number of channels: \(audioDevice.numberOfChannelsDescription())")
        print("")
    }
}

// MARK: - AMCoreAudioManagerDelegate Methods
extension AppDelegate : AMCoreAudioManagerDelegate {

    func hardwareDeviceListChangedWithAddedDevices(addedDevices: [AMCoreAudioDevice], andRemovedDevices removedDevices: [AMCoreAudioDevice]) {
        print("Devices added: \(addedDevices)")
        print("Devices removed: \(removedDevices)")
    }

    func hardwareDefaultInputDeviceChanged(audioDevice: AMCoreAudioDevice) {
        print("Default input device changed to \(audioDevice)")
    }

    func hardwareDefaultOutputDeviceChanged(audioDevice: AMCoreAudioDevice) {
        print("Default output device changed to \(audioDevice)")
    }

    func hardwareDefaultSystemDeviceChanged(audioDevice: AMCoreAudioDevice) {
        print("System output device changed to \(audioDevice)")
    }

    func audioDeviceNameDidChange(audioDevice: AMCoreAudioDevice) {
        print("\(audioDevice) name changed to \(audioDevice.deviceName())")
    }

    func audioDeviceListDidChange(audioDevice: AMCoreAudioDevice) {
        print("\(audioDevice) owned devices list changed")
    }

    func audioDeviceNominalSampleRateDidChange(audioDevice: AMCoreAudioDevice) {
        if let sampleRate = audioDevice.nominalSampleRate() {
            print("\(audioDevice) sample rate changed to \(sampleRate)")
        }
    }

    func audioDeviceVolumeDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction) {
        if let newVolume = audioDevice.volumeInDecibelsForChannel(channel, andDirection: direction) {
            print("\(audioDevice) volume for channel \(channel) and direction \(direction) changed to \(newVolume)dbFS")
        }
    }

    func audioDeviceMuteDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction) {
        if let isMuted = audioDevice.isChannelMuted(channel, andDirection: direction) {
            print("\(audioDevice) mute for channel \(channel) and direction \(direction) changed to \(isMuted)")
        }
    }

    func audioDeviceClockSourceDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction) {
        if let clockSourceName = audioDevice.clockSourceForChannel(channel, andDirection: direction) {
            print("\(audioDevice) clock source changed to \(clockSourceName)")
        }
    }

    func audioDeviceAvailableNominalSampleRatesDidChange(audioDevice: AMCoreAudioDevice) {
        if let nominalSampleRates = audioDevice.nominalSampleRates() {
            print("\(audioDevice) nominal sample rates changed to \(nominalSampleRates)")
        }
    }

    func audioDeviceIsAliveDidChange(audioDevice: AMCoreAudioDevice) {
        print("\(audioDevice) 'is alive' changed to \(audioDevice.isAlive())")
    }

    func audioDeviceIsRunningDidChange(audioDevice: AMCoreAudioDevice) {
        print("\(audioDevice) 'is running' changed to \(audioDevice.isRunning())")
    }

    func audioDeviceIsRunningSomewhereDidChange(audioDevice: AMCoreAudioDevice) {
        print("\(audioDevice) 'is running somewhere' changed to \(audioDevice.isRunningSomewhere())")
    }
}
