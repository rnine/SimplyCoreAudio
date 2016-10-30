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

    // Instantiate our audio hardware object
    private let audioHardware = AMAudioHardware.sharedInstance

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Enable audio hardware events
        audioHardware.enableDeviceMonitoring()

        // Subscribe to events
        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioHardwareEvent.self, dispatchQueue: DispatchQueue.main)
        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioStreamEvent.self, dispatchQueue: DispatchQueue.main)

        print("+ All known devices: \(AMAudioDevice.allDevices())")

        if let defaultOutputDevice = AMAudioDevice.defaultOutputDevice() {
            print("\n+ Default output device is '\(defaultOutputDevice.deviceName())':")
            printAudioDevice(defaultOutputDevice)
        }

        if let defaultInputDevice = AMAudioDevice.defaultInputDevice() {
            print("\n+ Default input device is '\(defaultInputDevice.deviceName())':")
            printAudioDevice(defaultInputDevice)
        }

        if let defaultSystemOutputDevice = AMAudioDevice.defaultSystemOutputDevice() {
            print("\n+ Default system output device is '\(defaultSystemOutputDevice.deviceName())':")
            printAudioDevice(defaultSystemOutputDevice)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Disable audio hardware events
        audioHardware.disableDeviceMonitoring()

        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioHardwareEvent.self)
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioDeviceEvent.self)
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioStreamEvent.self)
    }

    private func printAudioDevice(_ audioDevice: AMAudioDevice) {
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

        print("|- Preferred stereo channels for \(Direction.Playback): \(audioDevice.preferredStereoChannelsForDirection(.Playback))")

        print("|- Preferred stereo channels for \(Direction.Recording): \(audioDevice.preferredStereoChannelsForDirection(.Recording))")

        if let nominalSampleRates = audioDevice.nominalSampleRates() {
            print("|- Nominal sample rates: \(nominalSampleRates)")
        }

        if let nominalSampleRate = audioDevice.nominalSampleRate() {
            print("|- Nominal sample rate: \(nominalSampleRate)")
        }

        if let actualSampleRate = audioDevice.actualSampleRate() {
            print("|- Actual sample rate: \(actualSampleRate)")
        }

        if let playbackClockSources = audioDevice.clockSourcesForChannel(0, andDirection: .Playback) {
            print("|- Available clock sources for \(Direction.Playback): \(playbackClockSources)")
        }

        if let playbackClockSource = audioDevice.clockSourceForChannel(0, andDirection: .Playback) {
            print("|- Active clock source for \(Direction.Playback): \(playbackClockSource)")
        }

        if let recordingClockSources = audioDevice.clockSourcesForChannel(0, andDirection: .Recording) {
            print("|- Available clock sources for \(Direction.Recording): \(recordingClockSources)")
        }

        if let recordingClockSource = audioDevice.clockSourceForChannel(0, andDirection: .Recording) {
            print("|- Active clock source for \(Direction.Recording): \(recordingClockSource)")
        }

        if let playbackLatency = audioDevice.deviceLatencyFramesForDirection(.Playback) {
            print("|- \(Direction.Playback) latency: \(playbackLatency) frames")
        }

        if let recordingLatency = audioDevice.deviceLatencyFramesForDirection(.Recording) {
            print("|- \(Direction.Recording) latency: \(recordingLatency) frames")
        }

        if let playbackSafetyOffset = audioDevice.deviceSafetyOffsetFramesForDirection(.Playback) {
            print("|- \(Direction.Playback) safety offset: \(playbackSafetyOffset) frames")
        }

        if let recordingSafetyOffset = audioDevice.deviceSafetyOffsetFramesForDirection(.Recording) {
            print("|- \(Direction.Recording) safety offset: \(recordingSafetyOffset) frames")
        }

        let canSetMasterPlaybackVolume = audioDevice.canSetMasterVolumeForDirection(.Playback)
        print("|- Can set master \(Direction.Playback) volume? \(canSetMasterPlaybackVolume)")

        let canSetMasterRecordingVolume = audioDevice.canSetMasterVolumeForDirection(.Playback)
        print("|- Can set master \(Direction.Recording) volume? \(canSetMasterRecordingVolume)")

        if let masterPlaybackVolume = audioDevice.masterVolumeInDecibelsForDirection(.Playback) {
            print("|- \(Direction.Playback) master volume: \(masterPlaybackVolume)dbFS")

            if let masterPlaybackVolumeInfo = audioDevice.volumeInfoForChannel(UInt32(0), andDirection: .Playback) {
                print("|  - Volume info: \(masterPlaybackVolumeInfo)")
            }
        }

        if let masterRecordingVolume = audioDevice.masterVolumeInDecibelsForDirection(.Recording) {
            print("|- \(Direction.Recording) master volume: \(masterRecordingVolume)dbFS")

            if let masterRecordingVolumeInfo = audioDevice.volumeInfoForChannel(UInt32(0), andDirection: .Recording) {
                print("|  - Volume info: \(masterRecordingVolumeInfo)")
            }
        }

        let playbackChannels = audioDevice.channelsForDirection(.Playback)

        if playbackChannels > 0 {
            print("|- \(Direction.Playback) channel count is \(playbackChannels)")

            for channel in 0...playbackChannels {
                let nameForChannel = audioDevice.nameForChannel(channel, andDirection: .Playback) ?? (channel == 0 ? "Master" : "\(channel)")
                print("|  - Channel \(channel) (\(nameForChannel))")

                if let volume = audioDevice.volumeInDecibelsForChannel(channel, andDirection: .Playback) {
                    print("|    +- Volume: \(volume)")
                }
                if let volumeInfo = audioDevice.volumeInfoForChannel(channel, andDirection: .Playback) {
                    print("|    +- Volume info: \(volumeInfo)")
                }
            }
        }

        let recordingChannels = audioDevice.channelsForDirection(.Recording)

        if recordingChannels > 0 {
            print("|- \(Direction.Recording) channel count is \(recordingChannels)")

            for channel in 0...recordingChannels {
                let nameForChannel = audioDevice.nameForChannel(channel, andDirection: .Playback) ?? (channel == 0 ? "Master" : "\(channel)")

                print("|  - Channel \(channel) (\(nameForChannel))")

                if let volume = audioDevice.volumeInDecibelsForChannel(channel, andDirection: .Recording) {
                    print("|    +- Volume: \(volume)")
                }
                if let volumeInfo = audioDevice.volumeInfoForChannel(channel, andDirection: .Recording) {
                    print("|    +- Volume info: \(volumeInfo)")
                }
            }
        }

        if let streamForPlayback = audioDevice.streamsForDirection(.Playback) {
            print("|- Streams for playback: \(streamForPlayback)")

            streamForPlayback.forEach({ (stream) in
                print("|- Stream (playback): \(stream.streamID)")

                if let owningDevice = stream.owningDevice {
                    print("|- Owned by device: \(owningDevice)")
                }

                if let physicalFormats = stream.availablePhysicalFormats {
                    print("|- Available physical formats for playback (\(stream.streamID)): \(physicalFormats)")
                }

                if let virtualFormats = stream.availableVirtualFormats {
                    print("|- Available virtual formats for playback (\(stream.streamID)): \(virtualFormats)")
                }

                if let filteredPhysicalFormats = stream.availablePhysicalFormatsMatchingCurrentNominalSampleRate(false) {
                    print("|- Available physical formats for playback (filtered by sample rate) (\(stream.streamID)): \(filteredPhysicalFormats)")
                }

                if let filteredVirtualFormats = stream.availableVirtualFormatsMatchingCurrentNominalSampleRate(false) {
                    print("|- Available physical formats for playback (filtered by sample rate) (\(stream.streamID)): \(filteredVirtualFormats)")
                }

                if let physicalFormat = stream.physicalFormat {
                    print("|- Physical format for playback (\(stream.streamID)): \(physicalFormat)")
                }

                if let virtualFormat = stream.virtualFormat {
                    print("|- Virtual format for playback (\(stream.streamID)): \(virtualFormat)")
                }
            })
        }

        if let streamForRecording = audioDevice.streamsForDirection(.Recording) {
            print("|- Streams for recording: \(streamForRecording)")

            streamForRecording.forEach({ (stream) in
                print("|- Stream (recording): \(stream.streamID)")

                if let owningDevice = stream.owningDevice {
                    print("|- Owned by device: \(owningDevice)")
                }

                if let physicalFormats = stream.availablePhysicalFormats {
                    print("|- Available physical formats for recording (\(stream.streamID)): \(physicalFormats)")
                }

                if let virtualFormats = stream.availableVirtualFormats {
                    print("|- Available virtual formats for recording (\(stream.streamID)): \(virtualFormats)")
                }

                if let filteredPhysicalFormats = stream.availablePhysicalFormatsMatchingCurrentNominalSampleRate(false) {
                    print("|- Available physical formats for recording (filtered by sample rate) (\(stream.streamID)): \(filteredPhysicalFormats)")
                }

                if let filteredVirtualFormats = stream.availableVirtualFormatsMatchingCurrentNominalSampleRate(false) {
                    print("|- Available physical formats for recording (filtered by sample rate) (\(stream.streamID)): \(filteredVirtualFormats)")
                }

                if let physicalFormat = stream.physicalFormat {
                    print("|- Physical format for recording (\(stream.streamID)): \(physicalFormat)")
                }

                if let virtualFormat = stream.virtualFormat {
                    print("|- Virtual format for recording (\(stream.streamID)): \(virtualFormat)")
                }
            })
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
    }
}


// MARK: - AMEventSubscriber Protocol Implementation
extension AppDelegate : AMEventSubscriber {

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
