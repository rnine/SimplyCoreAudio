//
//  AMCoreAudioDevice.swift
//  AMCoreAudio
//
//  Created by Ruben on 7/7/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation
import CoreAudio.AudioHardwareBase
import AudioToolbox.AudioServices

public protocol AMCoreAudioDeviceDelegate: class {
    /*!
        Called whenever the audio device's sample rate changes.
    */
    func audioDeviceNominalSampleRateDidChange(audioDevice: AMCoreAudioDevice)

    /*!
        Called whenever the audio device's list of nominal sample rates changes.
        @note This will typically happen on Aggregate Devices and Multi-Output devices when adding or removing other audio devices (either physical or virtual).
    */
    func audioDeviceAvailableNominalSampleRatesDidChange(audioDevice: AMCoreAudioDevice)

    /*!
        Called whenever the audio device's clock source changes for a given channel and direction.
    */
    func audioDeviceClockSourceDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection)

    /*!
        Called whenever the audio device's name changes.
    */
    func audioDeviceNameDidChange(audioDevice: AMCoreAudioDevice)

    /*!
        Called whenever the list of owned audio devices on this audio device changes.
        @note This will typically happen on Aggregate Devices and Multi-Output devices when adding or removing other audio devices (either physical or virtual).
    */
    func audioDeviceListDidChange(audioDevice: AMCoreAudioDevice)

    /*!
        Called whenever the audio device's volume for a given channel and direction changes.
    */
    func audioDeviceVolumeDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection)

    /*!
        Called whenever the audio device's mute state for a given channel and direction changes.
    */
    func audioDeviceMuteDidChange(audioDevice: AMCoreAudioDevice, forChannel channel:UInt32, andDirection direction: AMCoreAudioDirection)

    /*!
        Called whenever the audio device's "is alive" flag changes.
    */
    func audioDeviceIsAliveDidChange(audioDevice: AMCoreAudioDevice)

    /*!
        Called whenever the audio device's "is running" flag changes.
    */
    func audioDeviceIsRunningDidChange(audioDevice: AMCoreAudioDevice)

    /*!
        Called whenever the audio device's "is running somewhere" flag changes.
    */
    func audioDeviceIsRunningSomewhereDidChange(audioDevice: AMCoreAudioDevice)
}

public class AMCoreAudioDevice: NSObject {

    let AMCoreAudioDefaultClockSourceName = "Default"

    /*!
        A delegate conforming to the AMCoreAudioDeviceDelegate protocol.
    */
    public weak var delegate: AMCoreAudioDeviceDelegate? {
        didSet {
            if self.delegate != nil {
                self.registerForNotifications()
            } else {
                self.unregisterForNotifications()
            }
        }
    }

    /*!
        The cached device name. This may be useful in some situations where the class instance
        is pointing to a device that is no longer available, so we can still access its name.

    @return The cached device name.
    */
    private(set) var cachedDeviceName: String?

    /*!
        An audio device identifier.

        @note
        This identifier will change with system restarts.
        If you need an unique identifier that is persists between restarts, use deviceUID instead.

        @return An audio device identifier.
    */
    public let deviceID: AudioObjectID

    private var isRegisteredForNotifications = false

    private lazy var notificationsQueue: dispatch_queue_t = {
        return dispatch_queue_create("io.9labs.AMCoreAudio.notifications", DISPATCH_QUEUE_CONCURRENT)
    }()

    private lazy var propertyListenerBlock: AudioObjectPropertyListenerBlock = { (inNumberAddresses, inAddresses) -> Void in

        let address: AudioObjectPropertyAddress = inAddresses.memory
        let direction = self.scopeToDirection(address.mScope)

        switch address.mSelector {
        case kAudioDevicePropertyNominalSampleRate:
            self.delegate?.audioDeviceNominalSampleRateDidChange(self)
        case kAudioDevicePropertyAvailableNominalSampleRates:
            self.delegate?.audioDeviceAvailableNominalSampleRatesDidChange(self)
        case kAudioDevicePropertyClockSource:
            self.delegate?.audioDeviceClockSourceDidChange(self, forChannel: address.mElement, andDirection: direction)
        case kAudioDevicePropertyDeviceNameCFString:
            self.delegate?.audioDeviceNameDidChange(self)
        case kAudioObjectPropertyOwnedObjects:
            self.delegate?.audioDeviceListDidChange(self)
        case kAudioDevicePropertyVolumeScalar:
            self.delegate?.audioDeviceVolumeDidChange(self, forChannel: address.mElement, andDirection: direction)
        case kAudioDevicePropertyMute:
            self.delegate?.audioDeviceMuteDidChange(self, forChannel: address.mElement, andDirection: direction)
        case kAudioDevicePropertyDeviceIsAlive:
            self.delegate?.audioDeviceIsAliveDidChange(self)
        case kAudioDevicePropertyDeviceIsRunning:
            self.delegate?.audioDeviceIsRunningDidChange(self)
        case kAudioDevicePropertyDeviceIsRunningSomewhere:
            self.delegate?.audioDeviceIsRunningSomewhereDidChange(self)
        // Unhandled cases beyond this point
        case kAudioDevicePropertyBufferSize:
            fallthrough
        case kAudioDevicePropertyBufferSizeRange:
            fallthrough
        case kAudioDevicePropertyBufferFrameSize:
            fallthrough
        case kAudioDevicePropertyStreamFormat:
            fallthrough
        case kAudioDevicePropertyPlayThru:
            fallthrough
        case kAudioDevicePropertyDataSource:
            fallthrough
        default:
            break
        }
    }

    /*!
        Initializes an AMCoreAudioDevice by providing a valid AudioObjectID referencing an existing audio device in the system.
    */
    public init(deviceID: AudioObjectID) {
        self.deviceID = deviceID
        super.init()
        cachedDeviceName = self.getDeviceName()
    }

    /*!
        Initializes an AMCoreAudioDevice that matches the provided audio UID, or nil if the UID is invalid.
    */
    public convenience init?(deviceUID: String) {
        var size = UInt32(sizeof(AudioValueTranslation))
        var objectID = AudioObjectID(0)
        var uid = deviceUID

        var translation = AudioValueTranslation(
            mInputData: &uid,
            mInputDataSize: UInt32(sizeof(CFStringRef)),
            mOutputData: &objectID,
            mOutputDataSize: UInt32(sizeof(AudioObjectID))
        )

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDeviceForUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(0), nil, &size, &translation)

        if (noErr == status) {
            self.init(deviceID: objectID)
        }

        return nil
    }

    deinit {
        delegate = nil
    }

    /*!
        The audio device's name as reported by the system.

        @return An audio device's name.
    */
    public func deviceName() -> String {
        return getDeviceName()
    }

    /*!
        Promotes a device to become the default system output device, output device, or input device.

        Valid types are:

        - kAudioHardwarePropertyDefaultSystemOutputDevice,
        - kAudioHardwarePropertyDefaultOutputDevice,
        - kAudioHardwarePropertyDefaultInputDevice.

        @return true on success, false otherwise.
    */
    public func setAsDefaultDevice(deviceType: AudioObjectPropertySelector) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: deviceType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var deviceID = self.deviceID
        let size = UInt32(sizeof(AudioObjectID))

        let status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(0), nil, size, &deviceID)

        return noErr == status
    }

    /*!
        An array of all the AudioObjectID's currently available in the system.
        @note: The list also includes Aggregate and Multi-Output Devices.

        @return An array of AudioObjectID's.
    */
    class func allDeviceIDs() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(0)
        var status: OSStatus

        status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            UInt32(0),
            nil,
            &size
        )

        if noErr != status {
            return []
        }

        var allIDs = [AudioObjectID](count:Int(size) / sizeof(AudioObjectID), repeatedValue: 0)

        status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(0), nil, &size, &allIDs)

        if noErr != status {
            return []
        }

        return allIDs
    }

    /*!
        An array of all the AMCoreAudioDevices currently available in the system.
        @note: The list also includes Aggregate and Multi-Output Devices.

        @return An array of AMCoreAudioDevices.
    */
    class func allDevices() -> [AMCoreAudioDevice] {
        let deviceIDs = allDeviceIDs()

        let devices = deviceIDs.map { (let deviceID) -> AMCoreAudioDevice in
            return AMCoreAudioDevice(deviceID: deviceID)
        }

        return devices
    }

    /*!
        An array of all the devices in the system that have at least one input.
        @note: The list may also include Aggregate Devices.

        @return An array of AMCoreAudioDevices.
    */
    class func allInputDevices() -> [AMCoreAudioDevice] {
        let devices = allDevices()

        return devices.filter({ (let device) -> Bool in
            return device.channelsForDirection(.Record) > 0
        })
    }

    /*!
        An array of all the devices in the system that have at least one output.
        @note: The list may also include Aggregate and Multi-Output Devices.

        @return An array of AMCoreAudioDevices.
    */
    class func allOutputDevices() -> [AMCoreAudioDevice] {
        let devices = allDevices()

        return devices.filter({ (let device) -> Bool in
            return device.channelsForDirection(.Playback) > 0
        })
    }

    class func defaultInputDevice() -> AMCoreAudioDevice? {
        return defaultDeviceOfType(kAudioHardwarePropertyDefaultInputDevice)
    }

    class func defaultOutputDevice() -> AMCoreAudioDevice? {
        return defaultDeviceOfType(kAudioHardwarePropertyDefaultOutputDevice)
    }

    class func defaultSystemOutputDevice() -> AMCoreAudioDevice? {
        return defaultDeviceOfType(kAudioHardwarePropertyDefaultSystemOutputDevice)
    }

    // MARK: - General Device Information Methods

    /*!
        An system audio device unique identifier.

        This identifier is guaranted to uniquely identify a device in the system
        and will not change even after restarts. Two (or more) identical audio devices
        are also guaranteed to have unique identifiers.

        @return A string with the audio device's unique identifier.
    */
    public func deviceUID() -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var uid: CFString = ""
        var size = UInt32(sizeof(CFStringRef))

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &uid)

        if (noErr != status) {
            return nil
        }

        return uid as String
    }

    /*!
        The audio device's manufacturer.

        @return A string with the audio device's manufacturer name.
    */
    public func deviceManufacturer() -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceManufacturerCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var manufacturer: CFString = ""
        var size = UInt32(sizeof(CFStringRef))

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &manufacturer)

        if (noErr != status) {
            return nil
        }

        return manufacturer as String
    }

    /*!
        The bundle ID for an application that provides a GUI for configuring the AudioDevice. 
        By default, the value of this property is the bundle ID for Audio MIDI Setup.

        @return A string pointing to the bundle ID
    */
    public func deviceConfigurationApplication() -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyConfigurationApplication,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var application: CFString = ""
        var size = UInt32(sizeof(CFStringRef))

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &application)

        if (noErr != status) {
            return nil
        }

        return application as String
    }

    /*!
        The audio device's image file that can be used to represent the device visually.

        @return An URL pointing to the image file
    */
    public func deviceIconURL() -> NSURL? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyIcon,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var url = NSURL()
        var size = UInt32(sizeof(CFURLRef))

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &url)

        if (noErr != status) {
            return nil
        }

        return url
    }

    /*!
        A human readable name for the channel number and direction specified.

        @return A string with the name of the channel.

    */
    public func nameForChannel(channel: UInt32, andDirection direction: AMCoreAudioDirection) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyElementName,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var name: CFString = ""
        var size = UInt32(sizeof(CFStringRef))
        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &name)

        if noErr != status {
            return nil
        }

        return name as String
    }

    /*!
        Whether the device is alive.

        @return true when the device is alive, false otherwise.
    */
    public func isAlive() -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsAlive,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(sizeof(UInt32))
        var valIsAlive = UInt32(0)

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &valIsAlive)

        if noErr != status {
            return false
        }
        
        return Bool(boolean: Boolean(valIsAlive))
    }

    /*!
        Whether the device is running.

        @return true when the device is running, false otherwise.
    */
    public func isRunning() -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunning,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(sizeof(UInt32))
        var valIsRunning = UInt32(0)

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &valIsRunning)

        if noErr != status {
            return false
        }

        return Bool(boolean: Boolean(valIsRunning))
    }

    /*!
        Whether the device is running somewhere.

        @return true when the device is running somewhere, false otherwise.
    */
    public func isRunningSomewhere() -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(sizeof(UInt32))
        var valIsRunningSomewhere = UInt32(0)

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &valIsRunningSomewhere)

        if noErr != status {
            return false
        }

        return Bool(boolean: Boolean(valIsRunningSomewhere))
    }

    // MARK: - Input/Output Layout Methods

    /*!
        The number of channels for a given direction.

        @return An UInt32 value.
    */
    public func channelsForDirection(direction: AMCoreAudioDirection) -> UInt32 {
        let channels = channelsByStreamForDirection(direction)
        return channels.reduce(0) { $0 + $1 }
    }

    /*!
        An array listing the number of channels per stream in a given direction.

        @return An array containing the list of channels.
    */
    public func channelsByStreamForDirection(direction: AMCoreAudioDirection) -> [UInt32] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        let hasProperty = Bool(boolean: AudioObjectHasProperty(deviceID, &address))

        if !hasProperty {
            return []
        }

        var status: OSStatus
        var size = UInt32(0)

        status = AudioObjectGetPropertyDataSize(deviceID, &address, UInt32(0), nil, &size)

        if noErr != status {
            return []
        }

        var audioBuffer = AudioBufferList()

        status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &audioBuffer)

        if noErr != status {
            return []
        }

        var result = [UInt32](count: Int(audioBuffer.mNumberBuffers), repeatedValue: 0)
        let abl = UnsafeMutableAudioBufferListPointer(&audioBuffer)

        for buffer in abl {
            result.append(buffer.mNumberChannels)
        }

        return result
    }

    /*!
        Whether the device has only inputs but no outputs.

        @return true when the device is input only, false otherwise.
    */
    public func isInputOnlyDevice() -> Bool {
        return channelsForDirection(.Playback) == 0 && channelsForDirection(.Record) > 0
    }

    /*!
        Whether the device has only outputs but no inputs.

        @return true when the device is output only, false otherwise.
    */
    public func isOutputOnlyDevice() -> Bool {
        return channelsForDirection(.Record) == 0 && channelsForDirection(.Playback) > 0
    }

    // MARK: - Individual Channel Methods

    /*!
        A AMCoreAudioVolumeInfo struct containing information about a particular channel and direction combination.

        @return A AMCoreAudioVolumeInfo struct.
    */
    public func volumeInfoForChannel(channel: UInt32, andDirection direction: AMCoreAudioDirection) -> AMCoreAudioVolumeInfo? {
        var volumeInfo = AMCoreAudioVolumeInfo()

        // obtain volume info
        var address: AudioObjectPropertyAddress

        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var status: OSStatus
        var hasProperty: Bool
        var size = UInt32()

        hasProperty = Bool(boolean: AudioObjectHasProperty(deviceID, &address))

        if !hasProperty {
            return nil
        }

        status = AudioObjectGetPropertyDataSize(deviceID, &address, UInt32(0), nil, &size)

        if noErr != status {
            return nil
        }

        var canSetVolumeBoolean = Boolean(0)
        status = AudioObjectIsPropertySettable(deviceID, &address, &canSetVolumeBoolean)

        if noErr == status {
            volumeInfo.canSetVolume = Bool(boolean: canSetVolumeBoolean)
            volumeInfo.hasVolume = true

            var volume = Float32(0)

            status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &volume)

            if noErr == status {
                volumeInfo.volume = volume
            } else {
                return nil
            }
        } else {
            return nil
        }

        // obtain mute info
        address.mSelector = kAudioDevicePropertyMute

        hasProperty = Bool(boolean: AudioObjectHasProperty(deviceID, &address))

        if !hasProperty {
            return nil
        }

        status = AudioObjectGetPropertyDataSize(deviceID, &address, UInt32(0), nil, &size)

        if noErr != status {
            return nil
        }

        var canMuteBoolean = Boolean(0)
        status = AudioObjectIsPropertySettable(deviceID, &address, &canMuteBoolean)

        if noErr == status {
            volumeInfo.canMute = Bool(boolean: canMuteBoolean)

            var isMuted = Boolean(0)

            status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &isMuted)

            if noErr == status {
                volumeInfo.isMuted = Bool(boolean: isMuted)
            } else {
                return nil
            }
        } else {
            return nil
        }

        // obtain play thru info
        address.mSelector = kAudioDevicePropertyPlayThru

        hasProperty = Bool(boolean: AudioObjectHasProperty(deviceID, &address))

        if !hasProperty {
            return nil
        }

        status = AudioObjectGetPropertyDataSize(deviceID, &address, UInt32(0), nil, &size)

        if noErr != status {
            return nil
        }

        var canPlayThruBoolean = Boolean(0)
        status = AudioObjectIsPropertySettable(deviceID, &address, &canPlayThruBoolean)

        if noErr == status {
            volumeInfo.canPlayThru = Bool(boolean: canPlayThruBoolean)

            var isPlayThruSet = Boolean(0)

            status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &isPlayThruSet)

            if noErr == status {
                volumeInfo.isPlayThruSet = Bool(boolean: isPlayThruSet)
            } else {
                return nil
            }
        } else {
            return nil
        }

        return volumeInfo
    }

    /*!
        The scalar volume for a given channel and direction.

        @return The scalar volume as a Float32 value.
    */
    public func volumeForChannel(channel: UInt32, andDirection direction: AMCoreAudioDirection) -> Float32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var size = UInt32(sizeof(Float32))
        var volume = Float32(0)

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &volume)

        if noErr != status {
            return nil
        }

        return volume
    }

    /*!
        The volume in decibels (dbFS) for a given channel and direction.

        @return The volume in decibels as a Float32 value.
    */
    public func volumeInDecibelsForChannel(channel: UInt32, andDirection direction: AMCoreAudioDirection) -> Float32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeDecibels,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var size = UInt32(sizeof(Float32))
        var volumeInDecibels = Float32(0)

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &volumeInDecibels)

        if noErr != status {
            return nil
        }

        return volumeInDecibels
    }

    /*!
        Sets the channel's volume for a given direction.

        @return true on success, false otherwise.
    */
    public func setVolume(volume: Float32, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: directionToScope(direction),
            mElement: channel
        )

        let size = UInt32(sizeof(Float32))
        var newVolume = volume

        let status = AudioObjectSetPropertyData(deviceID, &address, UInt32(0), nil, size, &newVolume)

        return noErr == status
    }

    /*!
        Mutes a channel for a given direction.

        @return true on success, false otherwise.
    */
    public func setMute(shouldMute: Bool, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: directionToScope(direction),
            mElement: channel
        )

        let size = UInt32(sizeof(UInt32))
        var willMute = UInt32(shouldMute == true ? 1 : 0)

        let status = AudioObjectSetPropertyData(deviceID, &address, UInt32(0), nil, size, &willMute)

        return noErr == status
    }

    /*!
        Whether a channel is muted for a given direction.

        @return true if channel is muted, false otherwise.
    */
    public func isChannelMuted(channel: UInt32, andDirection direction: AMCoreAudioDirection) -> Bool? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var size = UInt32(sizeof(UInt32))
        var valIsMuted = UInt32(0)

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &valIsMuted)

        if noErr != status {
            return nil
        }

        return Bool(boolean: Boolean(valIsMuted))
    }

    /*!
        Whether a channel can be muted for a given direction.

        @return true if channel can be muted, false otherwise.
    */
    public func canMuteForChannel(channel: UInt32, andDirection direction: AMCoreAudioDirection) -> Bool? {
        let volumeInfo = volumeInfoForChannel(channel, andDirection: direction)
        return volumeInfo?.canMute
    }

    /*!
        Whether a channel's volume can be set for a given direction.

        @return true if the channel's volume can be set, false otherwise.
    */
    public func canSetVolumeForChannel(channel: UInt32, andDirection direction: AMCoreAudioDirection) -> Bool {
        return volumeInfoForChannel(channel, andDirection: direction)?.canMute ?? false
    }

    /*!
        A list of channel numbers that best represent the preferred stereo channels
        used by this device (usually 1 and 2).

        @return An array containing channel numbers.
    */
    public func preferredStereoChannelsForDirection(direction: AMCoreAudioDirection) -> [UInt32] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var preferredChannels = [UInt32](count: 2, repeatedValue: 0)
        var size = UInt32(sizeof(UInt32) * 2)

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &preferredChannels)

        if noErr != status {
            return []
        } else {
            return preferredChannels
        }
    }

    // MARK: - Master Volume Methods

    /*!
        Whether the master volume can be muted for a given direction.

        @return true when the volume can be muted, false otherwise.
    */
    public func canMuteMasterVolumeForDirection(direction: AMCoreAudioDirection) -> Bool {
        if canMuteForChannel(kAudioObjectPropertyElementMaster, andDirection: direction) == true {
            return true
        }

        let preferredStereoChannels = preferredStereoChannelsForDirection(direction)

        if preferredStereoChannels.count == 0 {
            return false
        }

        let muteCount = preferredStereoChannels.filter { (channel) -> Bool in
            return canMuteForChannel(channel, andDirection: direction) == true
            }.count

        return muteCount == preferredStereoChannels.count
    }

    /*!
        Whether the master volume can be set for a given direction.

        @return true when the volume can be set, false otherwise.
    */
    public func canSetMasterVolumeForDirection(direction: AMCoreAudioDirection) -> Bool {
        if canSetVolumeForChannel(kAudioObjectPropertyElementMaster, andDirection: direction) == true {
            return true
        }

        let preferredStereoChannels = preferredStereoChannelsForDirection(direction)

        if preferredStereoChannels.count == 0 {
            return false
        }

        let canSetVolumeCount = preferredStereoChannels.filter { (channel) -> Bool in
            return canSetVolumeForChannel(channel, andDirection: direction) == true
            }.count

        return canSetVolumeCount == preferredStereoChannels.count
    }

    /*!
        Sets the master volume for a given direction.

        @return true on success, false otherwise.
    */
    public func setMasterVolume(volume: Float32, forDirection direction: AMCoreAudioDirection) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        let size = UInt32(sizeof(Float32))
        var theVolume = volume

        let status = AudioHardwareServiceSetPropertyData(deviceID, &address, UInt32(0), nil, size, &theVolume)

        return noErr == status
    }

    /*!
        Whether the volume is muted for a given direction.

        @return true if muted, false otherwise.
    */
    public func isMasterVolumeMutedForDirection(direction: AMCoreAudioDirection) -> Bool? {
        return isChannelMuted(kAudioObjectPropertyElementMaster, andDirection: direction)
    }

    /*!
        The master scalar volume for a given direction.

        @return The scalar volume as a Float32.
    */
    public func masterVolumeForDirection(direction: AMCoreAudioDirection) -> Float32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(sizeof(Float32))
        var volumeScalar = Float32(0)

        let status = AudioHardwareServiceGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &volumeScalar)

        if noErr != status {
            return nil
        }

        return volumeScalar
    }

    /*!
        The master volume in decibels for a given direction.

        @return The volume in decibels as a Float32.
    */
    public func masterVolumeInDecibelsForDirection(direction: AMCoreAudioDirection) -> Float32? {
        var volumeInDecibels = Float32(0)
        var referenceChannel: UInt32

        if canSetVolumeForChannel(kAudioObjectPropertyElementMaster, andDirection: direction) {
            referenceChannel = kAudioObjectPropertyElementMaster
        } else {
            var channels = preferredStereoChannelsForDirection(direction)

            if channels.count == 0 {
                return nil
            }

            referenceChannel = channels[0]
        }

        if let masterVolume = masterVolumeForDirection(direction),
               decibels = scalarToDecibels(masterVolume, forChannel: referenceChannel, andDirection: direction) {
            volumeInDecibels = decibels
        } else {
            return nil
        }

        return volumeInDecibels
    }

    // MARK: - Sample Rate Methods

    /*!
        The actual audio device's sample rate.

        @return A Float64 number.
    */
    public func actualSampleRate() -> Float64? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyActualSampleRate,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(sizeof(Float64))
        var sampleRate = Float64(0)
        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &sampleRate)

        if noErr != status {
            return nil
        }

        return sampleRate
    }

    /*!
        The nominal audio device's sample rate.

        @return A Float64 number.
    */
    public func nominalSampleRate() -> Float64? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(sizeof(Float64))
        var sampleRate = Float64(0)
        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &sampleRate)

        if noErr != status {
            return nil
        }

        return sampleRate
    }

    /*!
        Sets the nominal sample rate.

        @return true on success, false otherwise.
    */
    public func setNominalSampleRate(sampleRate: Float64) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        let size = UInt32(sizeof(Float64))
        var nominalSampleRate = sampleRate
        let status = AudioObjectSetPropertyData(deviceID, &address, UInt32(0), nil, size, &nominalSampleRate)

        return noErr == status
    }

    /*!
        A list of all the nominal sample rates supported by this audio device.
        @return An array of Float64 with all the nominal sample rates.
    */
    public func nominalSampleRates() -> [Float64]? {
        var sampleRates = [Float64]()

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyAvailableNominalSampleRates,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        let hasProperty = Bool(boolean: AudioObjectHasProperty(deviceID, &address))

        if !hasProperty {
            return nil
        }

        var size = UInt32(0)
        var status: OSStatus

        status = AudioObjectGetPropertyDataSize(deviceID, &address, UInt32(0), nil, &size)

        if noErr != status {
            return nil
        }

        // Sometimes an audio device will not support any sample rate.
        // For instance, this would be the case when an Aggregate Device
        // does not have any sub audio devices associated to it.
        // In this case, we will simply return an empty array
        if size == 0 {
            return nil
        }

        var valueRanges = [AudioValueRange](count: Int(size) / sizeof(AudioValueRange), repeatedValue: AudioValueRange())

        status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &valueRanges)

        if noErr != status {
            return nil
        }

        // A list of all the possible sample rates up to 192kHz
        // to be used in the case we receive a range (see below)
        let possibleRates: [Float64] = [
            6400, 8000, 11025, 12000,
            16000, 22050, 24000, 32000,
            44100, 48000, 64000, 88200,
            96000, 128000, 176400, 192000
        ]

        for valueRange in valueRanges {
            if valueRange.mMinimum < valueRange.mMaximum {
                // We got a range.
                //
                // This could be a headset audio device (i.e., CS50/CS60-USB Headset)
                // or a virtual audio driver (i.e., "System Audio Recorder" by WonderShare AllMyMusic)
                if let startIndex = possibleRates.indexOf(valueRange.mMinimum),
                       endIndex = possibleRates.indexOf(valueRange.mMaximum) {
                    sampleRates += possibleRates[startIndex..<endIndex + 1]
                } else {
                    print("Failed to obtain list of supported sample rates ranging from \(valueRange.mMinimum) to \(valueRange.mMaximum). This is an error in AMCoreAudio and should be reported to the project maintainers.")
                }
            } else {
                // We did not get a range (this should be the most common case)
                sampleRates.append(valueRange.mMinimum)
            }
        }

        return sampleRates
    }

    // MARK: - Clock Source Methods

    /*!
        The clock source name for the channel number and direction specified.

        @return A string containing the clock source name.
    */
    public func clockSourceForChannel(channel: UInt32, andDirection direction: AMCoreAudioDirection) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyClockSource,
            mScope: directionToScope(direction),
            mElement: channel
        )

        let hasProperty = Bool(boolean: AudioObjectHasProperty(deviceID, &address))

        if !hasProperty {
            return AMCoreAudioDefaultClockSourceName
        }

        var size = UInt32(sizeof(UInt32))
        var sourceID = UInt32(0)
        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &sourceID)

        if noErr != status {
            return nil
        }

        return clockSourceNameForClockSourceID(sourceID, forChannel: channel, andDirection: direction)
    }

    /*!
        A list of clock source names for the channel number and direction specified.

        @return An array containing all the clock source names.
    */
    public func clockSourcesForChannel(channel: UInt32, andDirection direction: AMCoreAudioDirection) -> [String]? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyClockSources,
            mScope: directionToScope(direction),
            mElement: channel
        )

        let hasProperty = Bool(boolean: AudioObjectHasProperty(deviceID, &address))

        if !hasProperty {
            return nil
        }

        var status: OSStatus
        var size = UInt32(0)
        status = AudioObjectGetPropertyDataSize(deviceID, &address, UInt32(0), nil, &size)

        if noErr != status {
            return nil
        }

        var clockSourceIDs = [UInt32](count: Int(size) / sizeof(UInt32), repeatedValue: 0)
        status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &clockSourceIDs)

        if noErr != status {
            return nil
        }

        return clockSourceIDs.map { (clockSourceID) -> String in
            return clockSourceNameForClockSourceID(clockSourceID, forChannel: channel, andDirection: direction)
        }
    }

    /*!
        Sets the clock source for a channel and direction.

        @return true on success, or false otherwise.
    */
    public func setClockSourceID(clockSourceID: UInt32, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyClockSource,
            mScope: directionToScope(direction),
            mElement: channel
        )

        let size = UInt32(sizeof(UInt32))
        var theClockSourceID = clockSourceID
        let status = AudioObjectSetPropertyData(deviceID, &address, UInt32(0), nil, size, &theClockSourceID)

        return noErr == status
    }

    // MARK: - Latency Methods

    /*!
        The latency in frames for the specified direction.

        @return The amount of frames as a UInt32 value.
    */
    public func deviceLatencyFramesForDirection(direction: AMCoreAudioDirection) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyLatency,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(sizeof(UInt32))
        var latencyFrames = UInt32(0)
        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &latencyFrames)

        if noErr != status {
            return nil
        }

        return latencyFrames
    }

    /*!
        The safety offset frames for the specified direction.

        @return The amount of frames as a UInt32 value.
    */
    public func deviceSafetyOffsetFramesForDirection(direction: AMCoreAudioDirection) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertySafetyOffset,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(sizeof(UInt32))
        var safetyOffsetFrames = UInt32(0)
        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &safetyOffsetFrames)

        if noErr != status {
            return nil
        }

        return safetyOffsetFrames
    }

    // MARK: - Hog Mode Methods

    /*!
        Indicates the pid that currently owns exclusive access to the AudioDevice or 
        a value of -1 indicating that the device is currently available to all processes.

        @return a pid_t value.
    */
    public func hogModePID() -> pid_t? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyHogMode,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(sizeof(pid_t))
        var pid = pid_t()
        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &pid)

        if noErr != status {
            return nil
        }

        return pid
    }

    /*!
        Attempts to set the pid that currently owns exclusive access to the
        AudioDevice.

        @return true on success, false otherwise.
    */
    public func setHogModePID(pid: pid_t) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyHogMode,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        let size = UInt32(sizeof(pid_t))
        var thePID = pid
        let status = AudioObjectSetPropertyData(deviceID, &address, UInt32(0), nil, size, &thePID)

        return noErr == status
    }

    /*!
        Attempts to set the pid that currently owns exclusive access to the
        AudioDevice to the current process.

        @return true on success, false otherwise.
    */
    public func setHogModePidToCurrentProcess() -> Bool {
        let currentPID = pid_t(NSProcessInfo.processInfo().processIdentifier)
        return setHogModePID(currentPID)
    }

    /*!
        Attempts to make the device available to all processes by setting the hog mode to -1.

        @return true on success, false otherwise.
    */
    public func unsetHogMode() -> Bool {
        return setHogModePID(pid_t(-1))
    }

    // MARK: - Volume Conversion Methods

    /*!
        Converts a scalar volume to a decibel (dbFS) volume
        for the given channel and direction.

        @return The converted decibel value as a Float32.
    */
    public func scalarToDecibels(volume: Float32, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection) -> Float32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalarToDecibels,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var size = UInt32(sizeof(Float32))
        var volumeInDecibels = -Float32.infinity
        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &volumeInDecibels)

        if noErr != status {
            return nil
        }

        return volumeInDecibels
    }

    /*!
        Converts a relative decibel (dbFS) volume to a scalar volume
        for the given channel and direction.

        @return The converted scalar value as a Float32.
    */
    public func decibelsToScalar(volume: Float32, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection) -> Float32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeDecibelsToScalar,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var size = UInt32(sizeof(Float32))
        var scalarVolume = Float32(0)
        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &scalarVolume)

        if noErr != status {
            return nil
        }

        return scalarVolume
    }

    // MARK: - Private Methods

    private func getDeviceName() -> String {
        var name: CFString = ""
        var size = UInt32(sizeof(CFStringRef))

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &name)

        if (noErr != status) {
            return "<Unknown Device Name>"
        } else {
            return name as String
        }
    }

    private func directionToScope(direction: AMCoreAudioDirection) -> AudioObjectPropertyScope {
        return .Playback == direction ? kAudioObjectPropertyScopeOutput : kAudioObjectPropertyScopeInput
    }

    private func scopeToDirection(scope: AudioObjectPropertyScope) -> AMCoreAudioDirection {
        switch scope {
        case kAudioObjectPropertyScopeOutput:
            return .Playback
        case kAudioObjectPropertyScopeInput:
            return .Record
        default:
            return .Invalid
        }
    }

    private func clockSourceNameForClockSourceID(clockSourceID: UInt32, forChannel channel: UInt32, andDirection direction: AMCoreAudioDirection) -> String {
        var name: CFString = ""
        var theClockSourceID = clockSourceID

        var translation = AudioValueTranslation(
            mInputData: &theClockSourceID,
            mInputDataSize: UInt32(sizeof(UInt32)),
            mOutputData: &name,
            mOutputDataSize: UInt32(sizeof(CFStringRef))
        )

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyClockSourceNameForIDCFString,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var size = UInt32(sizeof(AudioValueTranslation))
        let status = AudioObjectGetPropertyData(deviceID, &address, UInt32(0), nil, &size, &translation)

        if noErr != status {
            return AMCoreAudioDefaultClockSourceName
        }

        return name as String
    }

    private class func defaultDeviceOfType(deviceType: AudioObjectPropertySelector) -> AMCoreAudioDevice? {
        var address = AudioObjectPropertyAddress(
            mSelector: deviceType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var size = UInt32(sizeof(AudioObjectID))
        var audioDeviceID = AudioDeviceID()

        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(0), nil, &size, &audioDeviceID)

        if noErr != status {
            return nil
        }

        return AMCoreAudioDevice(deviceID: audioDeviceID)
    }

    // MARK: - Notification Book-keeping

    private func registerForNotifications() {
        if isRegisteredForNotifications {
            unregisterForNotifications()
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let err = AudioObjectAddPropertyListenerBlock(deviceID, &address, notificationsQueue, propertyListenerBlock)

        if noErr != err {
            print("Error on AudioObjectAddPropertyListenerBlock: \(err)", appendNewLine: true)
        }

        isRegisteredForNotifications = noErr == err
    }

    private func unregisterForNotifications() {
        if isRegisteredForNotifications {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertySelectorWildcard,
                mScope: kAudioObjectPropertyScopeWildcard,
                mElement: kAudioObjectPropertyElementWildcard
            )

            let err = AudioObjectRemovePropertyListenerBlock(deviceID, &address, notificationsQueue, propertyListenerBlock)

            if noErr != err {
                print("Error on AudioObjectRemovePropertyListenerBlock: \(err)", appendNewLine: true)
            }

            isRegisteredForNotifications = noErr != err
        }
    }
}

extension AMCoreAudioDevice {

    public override var description: String {
        return "<\(unsafeAddressOf(self)) id=\(deviceID), uid=\(deviceUID()!)> \(deviceName())"
    }
}

public func ==(lhs: AMCoreAudioDevice, rhs: AMCoreAudioDevice) -> Bool {
    return lhs.deviceID == rhs.deviceID
}
