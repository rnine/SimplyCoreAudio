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

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Enable audio hardware events
        audioHardware.enableDeviceMonitoring()

        // Subscribe to events
        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioHardwareEvent.self)
        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioDeviceEvent.self)
        AMNotificationCenter.defaultCenter.subscribe(self, eventType: AMAudioStreamEvent.self)

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

    func applicationWillTerminate(aNotification: NSNotification) {
        // Disable audio hardware events
        audioHardware.disableDeviceMonitoring()

        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioHardwareEvent.self)
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioDeviceEvent.self)
        AMNotificationCenter.defaultCenter.unsubscribe(self, eventType: AMAudioStreamEvent.self)
    }

    private func printAudioDevice(audioDevice: AMAudioDevice) {
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

    func eventReceiver(event: AMEvent) {
        switch event {
        case let event as AMAudioDeviceEvent:
            switch event {
            case .NominalSampleRateDidChange(let audioDevice):
                if let sampleRate = audioDevice.nominalSampleRate() {
                    print("\(audioDevice) sample rate changed to \(sampleRate)")
                }
            case .AvailableNominalSampleRatesDidChange(let audioDevice):
                if let nominalSampleRates = audioDevice.nominalSampleRates() {
                    print("\(audioDevice) nominal sample rates changed to \(nominalSampleRates)")
                }
            case .ClockSourceDidChange(let audioDevice, let channel, let direction):
                if let clockSourceName = audioDevice.clockSourceForChannel(channel, andDirection: direction) {
                    print("\(audioDevice) clock source changed to \(clockSourceName)")
                }
            case .NameDidChange(let audioDevice):
                print("\(audioDevice) name changed to \(audioDevice.deviceName())")
            case .ListDidChange(let audioDevice):
                print("\(audioDevice) owned devices list changed")
            case .VolumeDidChange(let audioDevice, let channel, let direction):
                if let newVolume = audioDevice.volumeInDecibelsForChannel(channel, andDirection: direction) {
                    print("\(audioDevice) volume for channel \(channel) and direction \(direction) changed to \(newVolume)dbFS")
                }
            case .MuteDidChange(let audioDevice, let channel, let direction):
                if let isMuted = audioDevice.isChannelMuted(channel, andDirection: direction) {
                    print("\(audioDevice) mute for channel \(channel) and direction \(direction) changed to \(isMuted)")
                }
            case .IsAliveDidChange(let audioDevice):
                print("\(audioDevice) 'is alive' changed to \(audioDevice.isAlive())")
            case .IsRunningDidChange(let audioDevice):
                print("\(audioDevice) 'is running' changed to \(audioDevice.isRunning())")
            case .IsRunningSomewhereDidChange(let audioDevice):
                print("\(audioDevice) 'is running somewhere' changed to \(audioDevice.isRunningSomewhere())")
            }
        case let event as AMAudioHardwareEvent:
            switch event {
            case .DeviceListChanged(let addedDevices, let removedDevices):
                print("Devices added: \(addedDevices)")
                print("Devices removed: \(removedDevices)")
            case .DefaultInputDeviceChanged(let audioDevice):
                print("Default input device changed to \(audioDevice)")
            case .DefaultOutputDeviceChanged(let audioDevice):
                print("Default output device changed to \(audioDevice)")
            case .DefaultSystemOutputDeviceChanged(let audioDevice):
                print("Default system output device changed to \(audioDevice)")
            }
        case let event as AMAudioStreamEvent:
            switch event {
            case .IsActiveDidChange(let audioStream):
                print("is active did change in \(audioStream)")
            case .PhysicalFormatDidChange(let audioStream):
                print("physical format did change in \(audioStream.streamID), owner: \(audioStream.owningDevice), format: \(audioStream.physicalFormat)")
            }
        default:
            break
        }
    }
}
