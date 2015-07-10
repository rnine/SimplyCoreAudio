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
    func audioDeviceClockSourceDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction)

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
    func audioDeviceVolumeDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction)

    /*!
        Called whenever the audio device's mute state for a given channel and direction changes.
    */
    func audioDeviceMuteDidChange(audioDevice: AMCoreAudioDevice, forChannel channel:UInt32, andDirection direction: Direction)

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

final public class AMCoreAudioDevice: NSObject {

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
        var deviceID = AudioObjectID(0)
        var uid = deviceUID

        var translation = AudioValueTranslation(
            mInputData: &uid,
            mInputDataSize: UInt32(sizeof(CFStringRef)),
            mOutputData: &deviceID,
            mOutputDataSize: UInt32(sizeof(AudioObjectID))
        )

        let address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDeviceForUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        let status = self.dynamicType.getPropertyData(AudioObjectID(kAudioObjectSystemObject), address: address, andValue: &translation)

        if noErr != status {
            return nil
        }

        self.init(deviceID: deviceID)
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
        let address = AudioObjectPropertyAddress(
            mSelector: deviceType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var deviceID = self.deviceID
        let status = setPropertyData(AudioObjectID(kAudioObjectSystemObject), address: address, andValue: &deviceID)

        return noErr == status
    }

    /*!
        An array of all the AudioObjectID's currently available in the system.
        @note: The list also includes Aggregate and Multi-Output Devices.

        @return An array of AudioObjectID's.
    */
    public class func allDeviceIDs() -> [AudioObjectID] {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)
        var allIDs = [AudioObjectID]()
        let status = getPropertyDataArray(systemObjectID, address: address, value: &allIDs, andDefaultValue: 0)

        return noErr == status ? allIDs : []
    }

    /*!
        An array of all the AMCoreAudioDevices currently available in the system.
        @note: The list also includes Aggregate and Multi-Output Devices.

        @return An array of AMCoreAudioDevices.
    */
    public class func allDevices() -> [AMCoreAudioDevice] {
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
    public class func allInputDevices() -> [AMCoreAudioDevice] {
        let devices = allDevices()

        return devices.filter({ (let device) -> Bool in
            return device.channelsForDirection(.Recording) > 0
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

    public class func defaultInputDevice() -> AMCoreAudioDevice? {
        return defaultDeviceOfType(kAudioHardwarePropertyDefaultInputDevice)
    }

    public class func defaultOutputDevice() -> AMCoreAudioDevice? {
        return defaultDeviceOfType(kAudioHardwarePropertyDefaultOutputDevice)
    }

    public class func defaultSystemOutputDevice() -> AMCoreAudioDevice? {
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
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var uid: CFString = ""
        let status = getPropertyData(address, andValue: &uid)

        return noErr == status ? (uid as String) : nil
    }

    /*!
    The audio device's model UID.

    @return A string with the audio device's model UID.
    */
    public func deviceModelUID() -> String? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyModelUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var manufacturer: CFString = ""
        let status = getPropertyData(address, andValue: &manufacturer)

        return noErr == status ? (manufacturer as String) : nil
    }
    
    /*!
        The audio device's manufacturer.

        @return A string with the audio device's manufacturer name.
    */
    public func deviceManufacturer() -> String? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceManufacturerCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var manufacturer: CFString = ""
        let status = getPropertyData(address, andValue: &manufacturer)

        return noErr == status ? (manufacturer as String) : nil
    }

    /*!
        The bundle ID for an application that provides a GUI for configuring the AudioDevice. 
        By default, the value of this property is the bundle ID for Audio MIDI Setup.

        @return A string pointing to the bundle ID
    */
    public func deviceConfigurationApplication() -> String? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyConfigurationApplication,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var application: CFString = ""
        let status = getPropertyData(address, andValue: &application)

        return noErr == status ? (application as String) : nil
    }

    /*!
        The audio device's image file that can be used to represent the device visually.

        @return An URL pointing to the image file
    */
    public func deviceIsHidden() -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyIsHidden,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var isHiddenValue = UInt32(0)
        let status = getPropertyData(address, andValue: &isHiddenValue)

        return noErr == status ? isHiddenValue != 0 : false
    }

    /*!
        A TransportType that indicates how the AudioDevice is connected to the CPU.

        @return A TransportType.
    */
    public func transportType() -> TransportType? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var transportType = UInt32(0)
        let status = getPropertyData(address, andValue: &transportType)

        if noErr == status {
            switch transportType {
            case kAudioDeviceTransportTypeBuiltIn:
                return .BuiltIn
            case kAudioDeviceTransportTypeAggregate:
                return .Aggregate
            case kAudioDeviceTransportTypeVirtual:
                return .Virtual
            case kAudioDeviceTransportTypePCI:
                return .PCI
            case kAudioDeviceTransportTypeUSB:
                return .USB
            case kAudioDeviceTransportTypeFireWire:
                return .FireWire
            case kAudioDeviceTransportTypeBluetooth:
                return .Bluetooth
            case kAudioDeviceTransportTypeBluetoothLE:
                return .BluetoothLE
            case kAudioDeviceTransportTypeHDMI:
                return .HDMI
            case kAudioDeviceTransportTypeDisplayPort:
                return .DisplayPort
            case kAudioDeviceTransportTypeAirPlay:
                return .AirPlay
            case kAudioDeviceTransportTypeAVB:
                return .AVB
            case kAudioDeviceTransportTypeThunderbolt:
                return .Thunderbolt
            case kAudioDeviceTransportTypeUnknown:
                fallthrough
            default:
                return .Unknown
            }
        }

        return nil
    }

    /*!
        A human readable name for the channel number and direction specified.

        @return A string with the name of the channel.

    */
    public func nameForChannel(channel: UInt32, andDirection direction: Direction) -> String? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyElementName,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var name: CFString = ""
        let status = getPropertyData(address, andValue: &name)

        if noErr == status {
            let theName = (name as String)
            return theName.isEmpty ? nil : theName
        }

        return nil
    }

    /*!
        An array of AudioObjectIDs that represent all the audio objects owned by the given object.
    
        @return An array of AudioObjectIDs
    */
    public func ownedObjectIDs() -> [AudioObjectID]? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyOwnedObjects,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var qualifierData = [kAudioObjectClassID]
        let qualifierDataSize = UInt32(sizeof(AudioClassID) * qualifierData.count)
        var ownedObjects = [AudioObjectID]()

        let status = getPropertyDataArray(address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &ownedObjects, andDefaultValue: AudioObjectID())

        return noErr == status ? ownedObjects : nil
    }

    /*!
        An array of AudioObjectIDs that represent the AudioControls of the audio device.

        @return An array of AudioObjectIDs
    */
    public func controlList() -> [AudioObjectID]? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyControlList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var controlList = [AudioObjectID]()
        let status = getPropertyDataArray(address, value: &controlList, andDefaultValue: AudioObjectID())

        return noErr == status ? controlList : nil
    }

    /*!
        An array of AMCoreAudioDevices for devices related to the AMCoreAudioDevice.
    
        @return An array of AMCoreAudioDevices
    */
    public func relatedDevices() -> [AMCoreAudioDevice]? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyRelatedDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var relatedDevices = [AudioDeviceID]()
        let status = getPropertyDataArray(address, value: &relatedDevices, andDefaultValue: AudioDeviceID())

        if noErr == status {
            return relatedDevices.map({ (deviceID) -> AMCoreAudioDevice in
                return AMCoreAudioDevice(deviceID: deviceID)
            })
        }

        return nil
    }

    /*!
        An AudioClassID that identifies the class of the AudioObject.
    
        @return An AudioClassID
    */
    public func classID() -> AudioClassID? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyClass,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var classID = AudioClassID()
        let status = getPropertyData(address, andValue: &classID)

        return noErr == status ? classID : nil
    }

    /*!
        Whether the device is alive.

        @return true when the device is alive, false otherwise.
    */
    public func isAlive() -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsAlive,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var valIsAlive = UInt32(0)
        let status = getPropertyData(address, andValue: &valIsAlive)

        return noErr == status ? Bool(boolean: Boolean(valIsAlive)) : false
    }

    /*!
        Whether the device is running.

        @return true when the device is running, false otherwise.
    */
    public func isRunning() -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunning,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var valIsRunning = UInt32(0)
        let status = getPropertyData(address, andValue: &valIsRunning)

        return noErr == status ? Bool(boolean: Boolean(valIsRunning)) : false
    }

    /*!
        Whether the device is running somewhere.

        @return true when the device is running somewhere, false otherwise.
    */
    public func isRunningSomewhere() -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var valIsRunningSomewhere = UInt32(0)
        let status = getPropertyData(address, andValue: &valIsRunningSomewhere)

        return noErr == status ? Bool(boolean: Boolean(valIsRunningSomewhere)) : false
    }

    // MARK: - Input/Output Layout Methods

    /*!
        The number of channels for a given direction.

        @return An UInt32 value.
    */
    public func channelsForDirection(direction: Direction) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelLayout,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        if Bool(boolean: AudioObjectHasProperty(deviceID, &address)) {
            var result = AudioChannelLayout()
            let status = getPropertyData(address, andValue: &result)

            return noErr == status ? result.mNumberChannelDescriptions : nil
        }

        return nil
    }

    /*!
        Whether the device has only inputs but no outputs.

        @return true when the device is input only, false otherwise.
    */
    public func isInputOnlyDevice() -> Bool {
        return channelsForDirection(.Playback) == 0 && channelsForDirection(.Recording) > 0
    }

    /*!
        Whether the device has only outputs but no inputs.

        @return true when the device is output only, false otherwise.
    */
    public func isOutputOnlyDevice() -> Bool {
        return channelsForDirection(.Recording) == 0 && channelsForDirection(.Playback) > 0
    }

    // MARK: - Individual Channel Methods

    /*!
        A VolumeInfo struct containing information about a particular channel and direction combination.

        @return A VolumeInfo struct.
    */
    public func volumeInfoForChannel(channel: UInt32, andDirection direction: Direction) -> VolumeInfo? {
        // obtain volume info
        var address: AudioObjectPropertyAddress

        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var volumeInfo = VolumeInfo()

        if Bool(boolean: AudioObjectHasProperty(deviceID, &address)) {
            var canSetVolumeBoolean = Boolean(0)
            var status = AudioObjectIsPropertySettable(deviceID, &address, &canSetVolumeBoolean)

            if noErr == status {
                volumeInfo.canSetVolume = Bool(boolean: canSetVolumeBoolean)
                volumeInfo.hasVolume = true

                var volume = Float32(0)
                status = getPropertyData(address, andValue: &volume)

                if noErr == status {
                    volumeInfo.volume = volume
                }
            }
        }

        // obtain mute info
        address.mSelector = kAudioDevicePropertyMute

        if Bool(boolean: AudioObjectHasProperty(deviceID, &address)) {
            var canMuteBoolean = Boolean(0)
            var status = AudioObjectIsPropertySettable(deviceID, &address, &canMuteBoolean)

            if noErr == status {
                volumeInfo.canMute = Bool(boolean: canMuteBoolean)

                var isMutedValue = UInt32(0)
                status = getPropertyData(address, andValue: &isMutedValue)

                if noErr == status {
                    volumeInfo.isMuted = Bool(boolean: Boolean(isMutedValue))
                }
            }
        }

        // obtain play thru info
        address.mSelector = kAudioDevicePropertyPlayThru

        if Bool(boolean: AudioObjectHasProperty(deviceID, &address)) {
            var canPlayThruBoolean = Boolean(0)
            var status = AudioObjectIsPropertySettable(deviceID, &address, &canPlayThruBoolean)

            if noErr == status {
                volumeInfo.canPlayThru = Bool(boolean: canPlayThruBoolean)

                var isPlayThruSetValue = UInt32(0)
                status = getPropertyData(address, andValue: &isPlayThruSetValue)

                if noErr == status {
                    volumeInfo.isPlayThruSet = Bool(boolean: Boolean(isPlayThruSetValue))
                }
            }
        }

        return volumeInfo
    }

    /*!
        The scalar volume for a given channel and direction.

        @return The scalar volume as a Float32 value.
    */
    public func volumeForChannel(channel: UInt32, andDirection direction: Direction) -> Float32? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var volume = Float32(0)
        let status = getPropertyData(address, andValue: &volume)

        return noErr == status ? volume : nil
    }

    /*!
        The volume in decibels (dbFS) for a given channel and direction.

        @return The volume in decibels as a Float32 value.
    */
    public func volumeInDecibelsForChannel(channel: UInt32, andDirection direction: Direction) -> Float32? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeDecibels,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var volumeInDecibels = Float32(0)
        let status = getPropertyData(address, andValue: &volumeInDecibels)

        return noErr == status ? volumeInDecibels : nil
    }

    /*!
        Sets the channel's volume for a given direction.

        @return true on success, false otherwise.
    */
    public func setVolume(volume: Float32, forChannel channel: UInt32, andDirection direction: Direction) -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var newVolume = volume
        let status = setPropertyData(address, andValue: &newVolume)

        return noErr == status
    }

    /*!
        Mutes a channel for a given direction.

        @return true on success, false otherwise.
    */
    public func setMute(shouldMute: Bool, forChannel channel: UInt32, andDirection direction: Direction) -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var willMute = UInt32(shouldMute == true ? 1 : 0)
        let status = setPropertyData(address, andValue: &willMute)

        return noErr == status
    }

    /*!
        Whether a channel is muted for a given direction.

        @return true if channel is muted, false otherwise.
    */
    public func isChannelMuted(channel: UInt32, andDirection direction: Direction) -> Bool? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var valIsMuted = UInt32(0)
        let status = getPropertyData(address, andValue: &valIsMuted)

        return noErr == status ? Bool(boolean: Boolean(valIsMuted)) : nil
    }

    /*!
        Whether a channel can be muted for a given direction.

        @return true if channel can be muted, false otherwise.
    */
    public func canMuteForChannel(channel: UInt32, andDirection direction: Direction) -> Bool {
        return volumeInfoForChannel(channel, andDirection: direction)?.canMute ?? false
    }

    /*!
        Whether a channel's volume can be set for a given direction.

        @return true if the channel's volume can be set, false otherwise.
    */
    public func canSetVolumeForChannel(channel: UInt32, andDirection direction: Direction) -> Bool {
        return volumeInfoForChannel(channel, andDirection: direction)?.canSetVolume ?? false
    }

    /*!
        A list of channel numbers that best represent the preferred stereo channels
        used by this device (usually 1 and 2).

        @return An array containing channel numbers.
    */
    public func preferredStereoChannelsForDirection(direction: Direction) -> [UInt32] {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var preferredChannels = [UInt32]()
        let status = getPropertyDataArray(address, value: &preferredChannels, andDefaultValue: 0)

        return noErr == status ? preferredChannels : []
    }

    // MARK: - Master Volume Methods

    /*!
        Whether the master volume can be muted for a given direction.

        @return true when the volume can be muted, false otherwise.
    */
    public func canMuteMasterVolumeForDirection(direction: Direction) -> Bool {
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
    public func canSetMasterVolumeForDirection(direction: Direction) -> Bool {
        if canSetVolumeForChannel(kAudioObjectPropertyElementMaster, andDirection: direction) == true {
            return true
        }

        let preferredStereoChannels = preferredStereoChannelsForDirection(direction)

        if preferredStereoChannels.count == 0 {
            return false
        }

        let canSetVolumeCount = preferredStereoChannels.filter { (channel) -> Bool in
            return canSetVolumeForChannel(channel, andDirection: direction)
        }.count

        return canSetVolumeCount == preferredStereoChannels.count
    }

    /*!
        Sets the master volume for a given direction.

        @return true on success, false otherwise.
    */
    public func setMasterVolume(volume: Float32, forDirection direction: Direction) -> Bool {
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
    public func isMasterVolumeMutedForDirection(direction: Direction) -> Bool? {
        return isChannelMuted(kAudioObjectPropertyElementMaster, andDirection: direction)
    }

    /*!
        The master scalar volume for a given direction.

        @return The scalar volume as a Float32.
    */
    public func masterVolumeForDirection(direction: Direction) -> Float32? {
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
    public func masterVolumeInDecibelsForDirection(direction: Direction) -> Float32? {
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
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyActualSampleRate,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        var sampleRate = Float64(0)
        let status = getPropertyData(address, andValue: &sampleRate)

        return noErr == status ? sampleRate : nil
    }

    /*!
        The nominal audio device's sample rate.

        @return A Float64 number.
    */
    public func nominalSampleRate() -> Float64? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        var sampleRate = Float64(0)
        let status = getPropertyData(address, andValue: &sampleRate)

        return noErr == status ? sampleRate : nil
    }

    /*!
        Sets the nominal sample rate.

        @return true on success, false otherwise.
    */
    public func setNominalSampleRate(sampleRate: Float64) -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        var nominalSampleRate = sampleRate
        let status = setPropertyData(address, andValue: &nominalSampleRate)

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

        var valueRanges = [AudioValueRange]()
        let status = getPropertyDataArray(address, value: &valueRanges, andDefaultValue: AudioValueRange())

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
    public func clockSourceForChannel(channel: UInt32, andDirection direction: Direction) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyClockSource,
            mScope: directionToScope(direction),
            mElement: channel
        )

        let hasProperty = Bool(boolean: AudioObjectHasProperty(deviceID, &address))

        if !hasProperty {
            return nil
        }

        var sourceID = UInt32(0)
        let status = getPropertyData(address, andValue: &sourceID)

        if noErr != status {
            return nil
        }

        return clockSourceNameForClockSourceID(sourceID, forChannel: channel, andDirection: direction)
    }

    /*!
        A list of clock source names for the channel number and direction specified.

        @return An array containing all the clock source names.
    */
    public func clockSourcesForChannel(channel: UInt32, andDirection direction: Direction) -> [String]? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyClockSources,
            mScope: directionToScope(direction),
            mElement: channel
        )

        let hasProperty = Bool(boolean: AudioObjectHasProperty(deviceID, &address))

        if !hasProperty {
            return nil
        }

        var clockSourceIDs = [UInt32]()
        let status = getPropertyDataArray(address, value: &clockSourceIDs, andDefaultValue: 0)

        if noErr != status {
            return nil
        }

        return clockSourceIDs.map { (clockSourceID) -> String in
            // We expect clockSourceNameForClockSourceID to never fail in this case, 
            // but in the unlikely case it does, we provide a default value.
            return clockSourceNameForClockSourceID(clockSourceID, forChannel: channel, andDirection: direction) ?? "Clock source \(clockSourceID)"
        }
    }

    /*!
        Sets the clock source for a channel and direction.

        @return true on success, or false otherwise.
    */
    public func setClockSourceID(clockSourceID: UInt32, forChannel channel: UInt32, andDirection direction: Direction) -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyClockSource,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var theClockSourceID = clockSourceID
        let status = setPropertyData(address, andValue: &theClockSourceID)

        return noErr == status
    }

    // MARK: - Latency Methods

    /*!
        The latency in frames for the specified direction.

        @return The amount of frames as a UInt32 value.
    */
    public func deviceLatencyFramesForDirection(direction: Direction) -> UInt32? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyLatency,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var latencyFrames = UInt32(0)
        let status = getPropertyData(address, andValue: &latencyFrames)

        return noErr == status ? latencyFrames : nil
    }

    /*!
        The safety offset frames for the specified direction.

        @return The amount of frames as a UInt32 value.
    */
    public func deviceSafetyOffsetFramesForDirection(direction: Direction) -> UInt32? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertySafetyOffset,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var safetyOffsetFrames = UInt32(0)
        let status = getPropertyData(address, andValue: &safetyOffsetFrames)

        return noErr == status ? safetyOffsetFrames : nil
    }

    // MARK: - Hog Mode Methods

    /*!
        Indicates the pid that currently owns exclusive access to the AudioDevice or 
        a value of -1 indicating that the device is currently available to all processes.

        @return a pid_t value.
    */
    public func hogModePID() -> pid_t? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyHogMode,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        var pid = pid_t()
        let status = getPropertyData(address, andValue: &pid)

        return noErr == status ? pid : nil
    }

    /*!
        Attempts to set the pid that currently owns exclusive access to the
        AudioDevice.

        @return true on success, false otherwise.
    */
    public func setHogModePID(pid: pid_t) -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyHogMode,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementMaster
        )

        var thePID = pid
        let status = setPropertyData(address, andValue: &thePID)

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
    public func scalarToDecibels(volume: Float32, forChannel channel: UInt32, andDirection direction: Direction) -> Float32? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalarToDecibels,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var volumeInDecibels = -Float32.infinity
        let status = getPropertyData(address, andValue: &volumeInDecibels)

        return noErr == status ? volumeInDecibels : nil
    }

    /*!
        Converts a relative decibel (dbFS) volume to a scalar volume
        for the given channel and direction.

        @return The converted scalar value as a Float32.
    */
    public func decibelsToScalar(volume: Float32, forChannel channel: UInt32, andDirection direction: Direction) -> Float32? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeDecibelsToScalar,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var scalarVolume = Float32(0)
        let status = getPropertyData(address, andValue: &scalarVolume)

        return noErr == status ? scalarVolume : nil
    }

    // MARK: - Private Methods

    private class func getPropertyDataSize<Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout andSize size: UInt32) -> (OSStatus) {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(deviceID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }

    private class func getPropertyDataSize<Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout andSize size: UInt32) -> (OSStatus) {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(deviceID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }

    private class func getPropertyDataSize(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andSize size: UInt32) -> (OSStatus) {
        var nilValue: NilLiteralConvertible?
        return getPropertyDataSize(deviceID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, andSize: &size)
    }

    private class func getPropertyData<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        var theAddress = address
        var size = UInt32(sizeof(T))
        let status = AudioObjectGetPropertyData(deviceID, &theAddress, UInt32(0), nil, &size, &value)

        return status
    }

    private class func getPropertyDataArray<T,Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        var size = UInt32(0)
        let sizeStatus = getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)

        if noErr == sizeStatus {
            value = [T](count: Int(size) / sizeof(T), repeatedValue: defaultValue)
        } else {
            return sizeStatus
        }

        var theAddress = address
        let status = AudioObjectGetPropertyData(deviceID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size, &value)

        return status
    }

    private class func getPropertyDataArray<T,Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        var size = UInt32(0)
        let sizeStatus = getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)

        if noErr == sizeStatus {
            value = [T](count: Int(size) / sizeof(T), repeatedValue: defaultValue)
        } else {
            return sizeStatus
        }

        var theAddress = address
        let status = AudioObjectGetPropertyData(deviceID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size, &value)
        
        return status
    }

    private class func getPropertyDataArray<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        var nilValue: NilLiteralConvertible?
        return getPropertyDataArray(deviceID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, value: &value, andDefaultValue: defaultValue)
    }

    private func getPropertyDataSize<Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    private func getPropertyDataSize<Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    private func getPropertyDataSize(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andSize size: UInt32) -> OSStatus {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, andSize: &size)
    }

    private func getPropertyDataSize<Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    private func getPropertyDataSize<Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    private func getPropertyDataSize(address: AudioObjectPropertyAddress, inout andSize size: UInt32) -> OSStatus {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, andSize: &size)
    }

    private func getPropertyData<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        return self.dynamicType.getPropertyData(deviceID, address: address, andValue: &value)
    }

    private func getPropertyDataArray<T,Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    private func getPropertyDataArray<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return getPropertyDataArray(deviceID, address: address, value: &value, andDefaultValue: defaultValue)
    }

    private func getPropertyData<T>(address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        return self.dynamicType.getPropertyData(deviceID, address: address, andValue: &value)
    }

    private func getPropertyDataArray<T,Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    private func getPropertyDataArray<T,Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    private func getPropertyDataArray<T>(address: AudioObjectPropertyAddress, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(deviceID, address: address, value: &value, andDefaultValue: defaultValue)
    }

    private func setPropertyData<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        var theAddress = address
        let size = UInt32(sizeof(T))
        let status = AudioObjectSetPropertyData(deviceID, &theAddress, UInt32(0), nil, size, &value)

        return status
    }

    private func setPropertyData<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andValue value: [T]) -> OSStatus {
        var theAddress = address
        let size = UInt32(value.count * sizeof(T))
        let status = AudioObjectSetPropertyData(deviceID, &theAddress, UInt32(0), nil, size, &value)

        return status
    }

    private func setPropertyData<T>(address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        return setPropertyData(deviceID, address: address, andValue: &value)
    }

    private func setPropertyData<T>(address: AudioObjectPropertyAddress, inout andValue value: [T]) -> OSStatus {
        return setPropertyData(deviceID, address: address, andValue: &value)
    }

    private func getDeviceName() -> String {
        var name: CFString = ""

        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        let status = getPropertyData(address, andValue: &name)

        return noErr == status ? (name as String) : (cachedDeviceName ?? "<Unknown Device Name>")
    }

    private func directionToScope(direction: Direction) -> AudioObjectPropertyScope {
        return .Playback == direction ? kAudioObjectPropertyScopeOutput : kAudioObjectPropertyScopeInput
    }

    private func scopeToDirection(scope: AudioObjectPropertyScope) -> Direction {
        switch scope {
        case kAudioObjectPropertyScopeOutput:
            return .Playback
        case kAudioObjectPropertyScopeInput:
            return .Recording
        default:
            return .Invalid
        }
    }

    private func clockSourceNameForClockSourceID(clockSourceID: UInt32, forChannel channel: UInt32, andDirection direction: Direction) -> String? {
        var name: CFString = ""
        var theClockSourceID = clockSourceID

        var translation = AudioValueTranslation(
            mInputData: &theClockSourceID,
            mInputDataSize: UInt32(sizeof(UInt32)),
            mOutputData: &name,
            mOutputDataSize: UInt32(sizeof(CFStringRef))
        )

        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyClockSourceNameForIDCFString,
            mScope: directionToScope(direction),
            mElement: channel
        )

        let status = getPropertyData(address, andValue: &translation)

        return noErr == status ? (name as String) : nil
    }

    private class func defaultDeviceOfType(deviceType: AudioObjectPropertySelector) -> AMCoreAudioDevice? {
        let address = AudioObjectPropertyAddress(
            mSelector: deviceType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var audioDeviceID = AudioDeviceID()
        let status = getPropertyData(AudioObjectID(kAudioObjectSystemObject), address: address, andValue: &audioDeviceID)

        return noErr == status ? AMCoreAudioDevice(deviceID: audioDeviceID) : nil
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
            print("Error on AudioObjectAddPropertyListenerBlock: \(err)")
        }

        isRegisteredForNotifications = noErr == err
    }

    private func unregisterForNotifications() {
        if isAlive() && isRegisteredForNotifications {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertySelectorWildcard,
                mScope: kAudioObjectPropertyScopeWildcard,
                mElement: kAudioObjectPropertyElementWildcard
            )

            let err = AudioObjectRemovePropertyListenerBlock(deviceID, &address, notificationsQueue, propertyListenerBlock)

            if noErr != err {
                print("Error on AudioObjectRemovePropertyListenerBlock: \(err)")
            }

            isRegisteredForNotifications = noErr != err
        } else {
            isRegisteredForNotifications = false
        }
    }
}

extension AMCoreAudioDevice {

    public override var hashValue: Int {
        return Int(deviceID)
    }

    public override var description: String {
        return "\(deviceName()) (\(deviceID))"
    }
}

func ==(lhs: AMCoreAudioDevice, rhs: AMCoreAudioDevice) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
