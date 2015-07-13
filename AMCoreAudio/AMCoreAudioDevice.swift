//
//  AMCoreAudioDevice.swift
//  AMCoreAudio
//
//  Created by Ruben on 7/7/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation
import AudioToolbox.AudioServices

/// `AMCoreAudioDeviceDelegate` protocol
public protocol AMCoreAudioDeviceDelegate: class {

    /**
        Called whenever the audio device's sample rate changes.
    */
    func audioDeviceNominalSampleRateDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's list of nominal sample rates changes.
        
        **Note:** This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other audio devices (either physical or virtual.)
    */
    func audioDeviceAvailableNominalSampleRatesDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's clock source changes for a given channel and direction.
    */
    func audioDeviceClockSourceDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction)

    /**
        Called whenever the audio device's name changes.
    */
    func audioDeviceNameDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the list of owned audio devices on this audio device changes.

        **Note:** This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other audio devices (either physical or virtual.)
    */
    func audioDeviceListDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's volume for a given channel and direction changes.
    */
    func audioDeviceVolumeDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction)

    /**
        Called whenever the audio device's mute state for a given channel and direction changes.
    */
    func audioDeviceMuteDidChange(audioDevice: AMCoreAudioDevice, forChannel channel:UInt32, andDirection direction: Direction)

    /**
        Called whenever the audio device's *is alive* flag changes.
    */
    func audioDeviceIsAliveDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's *is running* flag changes.
    */
    func audioDeviceIsRunningDidChange(audioDevice: AMCoreAudioDevice)

    /**
        Called whenever the audio device's *is running somewhere* flag changes.
    */
    func audioDeviceIsRunningSomewhereDidChange(audioDevice: AMCoreAudioDevice)
}

/// Optional `AMCoreAudioDeviceDelegate` protocol methods
public extension AMCoreAudioDeviceDelegate {

    func audioDeviceNominalSampleRateDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceAvailableNominalSampleRatesDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceClockSourceDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction) {}
    func audioDeviceNameDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceListDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceVolumeDidChange(audioDevice: AMCoreAudioDevice, forChannel channel: UInt32, andDirection direction: Direction) {}
    func audioDeviceMuteDidChange(audioDevice: AMCoreAudioDevice, forChannel channel:UInt32, andDirection direction: Direction) {}
    func audioDeviceIsAliveDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceIsRunningDidChange(audioDevice: AMCoreAudioDevice) {}
    func audioDeviceIsRunningSomewhereDidChange(audioDevice: AMCoreAudioDevice) {}
}

/**
    `AMCoreAudioDevice`

    This class represents an audio device in the system and 
    allows subscribing to audio device notifications.

    Devices may be physical or virtual. For a comprehensive list of
    supported types, please refer to `TransportType`.
*/
final public class AMCoreAudioDevice: NSObject {

    /**
        A delegate conforming to the `AMCoreAudioDeviceDelegate` protocol.
    */
    public weak var delegate: AMCoreAudioDeviceDelegate? {
        didSet {
            if delegate != nil {
                registerForNotifications()
            } else {
                unregisterForNotifications()
            }
        }
    }

    /**
        The cached device name. This may be useful in some situations where the class instance
        is pointing to a device that is no longer available, so we can still access its name.

        - Returns: The cached device name.
    */
    private(set) var cachedDeviceName: String!

    /**
        An audio device identifier.

        **Note:**
        This identifier will change with system restarts.
        If you need an unique identifier that persists between restarts, use `deviceUID()` instead.

        - Returns: An audio device identifier.
    */
    public let deviceID: AudioObjectID

    private var isRegisteredForNotifications = false

    private lazy var notificationsQueue: dispatch_queue_t = {
        return dispatch_queue_create("io.9labs.AMCoreAudio.notifications", DISPATCH_QUEUE_CONCURRENT)
    }()

    private lazy var propertyListenerBlock: AudioObjectPropertyListenerBlock = { (inNumberAddresses, inAddresses) -> Void in

        let address = inAddresses.memory
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

    /**
        Initializes an `AMCoreAudioDevice` by providing a valid `AudioObjectID` referencing an existing audio device in the system.
    */
    public init(deviceID: AudioObjectID) {
        self.deviceID = deviceID
        super.init()
        cachedDeviceName = getDeviceName()
    }

    /**
        Initializes an `AMCoreAudioDevice` that matches the provided audio device `UID`, or nil if the `UID` is invalid.
    */
    public convenience init?(deviceUID: String) {
        var deviceID = AudioObjectID(0)
        let status = AMAudioHardwarePropertyDeviceForUID(deviceUID, &deviceID)

        if noErr != status || deviceID == kAudioDeviceUnknown {
            return nil
        }

        self.init(deviceID: deviceID)
    }

    deinit {
        delegate = nil
    }

    /**
        Promotes a device to become the default system output device, output device, or input device.

        Valid types are:

        - kAudioHardwarePropertyDefaultSystemOutputDevice,
        - kAudioHardwarePropertyDefaultOutputDevice,
        - kAudioHardwarePropertyDefaultInputDevice.

        - Returns: `true` on success, `false` otherwise.
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

    // MARK: - Class Methods

    /**
        An array of all the `AudioObjectID`'s currently available in the system.
        
        **Note:** The list may also include *Aggregate* and *Multi-Output* devices.

        - Returns: An array of `AudioObjectID`'s.
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

    /**
        An array of all the `AMCoreAudioDevice`s currently available in the system.
        
        **Note:** The list may also include *Aggregate* and *Multi-Output* devices.

        - Returns: An array of `AMCoreAudioDevice`s.
    */
    public class func allDevices() -> [AMCoreAudioDevice] {
        let deviceIDs = allDeviceIDs()

        let devices = deviceIDs.map { (let deviceID) -> AMCoreAudioDevice in
            return AMCoreAudioDevice(deviceID: deviceID)
        }

        return devices
    }

    /**
        An array of all the devices in the system that have at least one input.
        
        **Note:** The list may also include *Aggregate* devices.

        - Returns: An array of `AMCoreAudioDevice`s.
    */
    public class func allInputDevices() -> [AMCoreAudioDevice] {
        let devices = allDevices()

        return devices.filter({ (let device) -> Bool in
            return device.channelsForDirection(.Recording) > 0
        })
    }

    /**
        An array of all the devices in the system that have at least one output.
        
        **Note:** The list may also include *Aggregate* and *Multi-Output* devices.

        - Returns: An array of `AMCoreAudioDevice`s.
    */
    public class func allOutputDevices() -> [AMCoreAudioDevice] {
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

    // MARK: - ✪ General Device Information Methods

    /**
        The audio device's name as reported by the system.

        - Returns: An audio device's name.
    */
    public func deviceName() -> String {
        return getDeviceName()
    }

    /**
        An system audio device unique identifier.

        This identifier is guaranted to uniquely identify a device in the system
        and will not change even after restarts. Two (or more) identical audio devices
        are also guaranteed to have unique identifiers.

        - Returns: *(optional)* A `String` with the audio device `UID`.
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

    /**
        The audio device's model `UID`.

        - Returns: *(optional)* A `String` with the audio device's model `UID`.
    */
    public func deviceModelUID() -> String? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyModelUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var modelUID: CFString = ""
        let status = getPropertyData(address, andValue: &modelUID)

        return noErr == status ? (modelUID as String) : nil
    }
    
    /**
        The audio device's manufacturer.

        - Returns: *(optional)* A `String` with the audio device's manufacturer name.
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

    /**
        The bundle ID for an application that provides a GUI for configuring the AudioDevice. 
        By default, the value of this property is the bundle ID for *Audio MIDI Setup*.

        - Returns: *(optional)* A `String` pointing to the bundle ID
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

    /**
        Whether the audio device is included in the normal list of devices.
        
        **Note:** Hidden devices can only be discovered by knowing their `UID` and
        using `kAudioHardwarePropertyDeviceForUID`.

        - Returns: `true` when device is hidden, `false` otherwise.
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

    /**
        A `TransportType` that indicates how the audio device is connected to the CPU.

        - Returns: *(optional)* A `TransportType`.
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

    /**
        A human readable name for the channel number and direction specified.

        - Returns: *(optional)* A `String` with the name of the channel.
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

    /**
        An array of `AudioObjectID`s that represent all the audio objects owned by the given object.
    
        - Returns: *(optional)* An array of `AudioObjectID`s.
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

    /**
        An array of `AudioObjectID`s that represent the audio controls of the audio device.

        - Returns: *(optional)* An array of `AudioObjectID`s.
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

    /**
        An array of `AMCoreAudioDevice`s for devices related to the `AMCoreAudioDevice`.
    
        - Returns: *(optional)* An array of `AMCoreAudioDevice`s.
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

    /**
        An `AudioClassID` that identifies the class of the audio object.
    
        - Returns: *(optional)* An `AudioClassID`.
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

    /**
        Whether the device is alive.

        - Returns: `true` when the device is alive, `false` otherwise.
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

    /**
        Whether the device is running.

        - Returns: `true` when the device is running, `false` otherwise.
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

    /**
        Whether the device is running somewhere.

        - Returns: `true` when the device is running somewhere, `false` otherwise.
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

    // MARK: - ⇄ Input/Output Layout Methods

    /**
        The number of channels for a given direction.

        - Returns: *(optional)* A `UInt32` with the number of channels.
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

    /**
        Whether the device has only inputs but no outputs.

        - Returns: `true` when the device is input only, `false` otherwise.
    */
    public func isInputOnlyDevice() -> Bool {
        return channelsForDirection(.Playback) == 0 && channelsForDirection(.Recording) > 0
    }

    /**
        Whether the device has only outputs but no inputs.

        - Returns: `true` when the device is output only, `false` otherwise.
    */
    public func isOutputOnlyDevice() -> Bool {
        return channelsForDirection(.Recording) == 0 && channelsForDirection(.Playback) > 0
    }

    // MARK: - ⇉ Individual Channel Methods

    /**
        A `VolumeInfo` struct containing information about a particular channel and direction combination.

        - Returns: *(optional)* A `VolumeInfo` struct.
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

    /**
        The scalar volume for a given channel and direction.

        - Returns: *(optional)* A `Float32` value with the scalar volume.
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

    /**
        The volume in decibels *(dbFS)* for a given channel and direction.

        - Returns: *(optional)* A `Float32` value with the volume in decibels.
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

    /**
        Sets the channel's volume for a given direction.

        - Returns: `true` on success, `false` otherwise.
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

    /**
        Mutes a channel for a given direction.

        - Returns: `true` on success, `false` otherwise.
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

    /**
        Whether a channel is muted for a given direction.

        - Returns: *(optional)* `true` if channel is muted, false otherwise.
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

    /**
        Whether a channel can be muted for a given direction.

        - Returns: `true` if channel can be muted, `false` otherwise.
    */
    public func canMuteForChannel(channel: UInt32, andDirection direction: Direction) -> Bool {
        return volumeInfoForChannel(channel, andDirection: direction)?.canMute ?? false
    }

    /**
        Whether a channel's volume can be set for a given direction.

        - Returns: `true` if the channel's volume can be set, `false` otherwise.
    */
    public func canSetVolumeForChannel(channel: UInt32, andDirection direction: Direction) -> Bool {
        return volumeInfoForChannel(channel, andDirection: direction)?.canSetVolume ?? false
    }

    /**
        A list of channel numbers that best represent the preferred stereo channels
        used by this device (usually `1` and `2`).

        - Returns: A `UInt32` array containing the channel numbers.
    */
    public func preferredStereoChannelsForDirection(direction: Direction) -> [UInt32]? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var preferredChannels = [UInt32]()
        let status = getPropertyDataArray(address, value: &preferredChannels, andDefaultValue: 0)

        return noErr == status ? preferredChannels : nil
    }

    // MARK: - 🔊 Master Volume Methods

    /**
        Whether the master volume can be muted for a given direction.

        - Returns: `true` when the volume can be muted, `false` otherwise.
    */
    public func canMuteMasterVolumeForDirection(direction: Direction) -> Bool {
        if canMuteForChannel(kAudioObjectPropertyElementMaster, andDirection: direction) == true {
            return true
        }

        if let preferredStereoChannels = preferredStereoChannelsForDirection(direction) {
            let muteCount = preferredStereoChannels.filter { (channel) -> Bool in
                return canMuteForChannel(channel, andDirection: direction) == true
            }.count

            return muteCount == preferredStereoChannels.count
        }

        return false
    }

    /**
        Whether the master volume can be set for a given direction.

        - Returns: `true` when the volume can be set, `false` otherwise.
    */
    public func canSetMasterVolumeForDirection(direction: Direction) -> Bool {
        if canSetVolumeForChannel(kAudioObjectPropertyElementMaster, andDirection: direction) == true {
            return true
        }

        if let preferredStereoChannels = preferredStereoChannelsForDirection(direction) {

            let canSetVolumeCount = preferredStereoChannels.filter { (channel) -> Bool in
                return canSetVolumeForChannel(channel, andDirection: direction)
            }.count

            return canSetVolumeCount == preferredStereoChannels.count
        }

        return false
    }

    /**
        Sets the master volume for a given direction.

        **Note:** The volume is given as a scalar value (i.e., 0 to 1)

        - Returns: `true` on success, `false` otherwise.
    */
    public func setMasterVolume(volume: Float32, forDirection direction: Direction) -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var theVolume = volume
        let status = setPropertyData(address, andValue: &theVolume)

        return noErr == status
    }

    /**
        Whether the volume is muted for a given direction.

        - Returns: `true` when muted, `false` otherwise.
    */
    public func isMasterVolumeMutedForDirection(direction: Direction) -> Bool? {
        return isChannelMuted(kAudioObjectPropertyElementMaster, andDirection: direction)
    }

    /**
        The master scalar volume for a given direction.

        - Returns: *(optional)* A `Float32` value with the scalar volume.
    */
    public func masterVolumeForDirection(direction: Direction) -> Float32? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var volumeScalar = Float32(0)
        let status = getPropertyData(address, andValue: &volumeScalar)

        if noErr != status {
            return nil
        }

        return volumeScalar
    }

    /**
        The master volume in decibels for a given direction.

        - Returns: *(optional)* A `Float32` value with the volume in decibels.
    */
    public func masterVolumeInDecibelsForDirection(direction: Direction) -> Float32? {
        var volumeInDecibels = Float32(0)
        var referenceChannel: UInt32

        if canSetVolumeForChannel(kAudioObjectPropertyElementMaster, andDirection: direction) {
            referenceChannel = kAudioObjectPropertyElementMaster
        } else {
            if let channels = preferredStereoChannelsForDirection(direction) {
                referenceChannel = channels[0]
            } else {
                return nil
            }
        }

        if let masterVolume = masterVolumeForDirection(direction),
               decibels = scalarToDecibels(masterVolume, forChannel: referenceChannel, andDirection: direction) {
            volumeInDecibels = decibels
        } else {
            return nil
        }

        return volumeInDecibels
    }

    // MARK: - 〰 Sample Rate Methods

    /**
        The actual audio device's sample rate.

        - Returns: *(optional)* A `Float64` value with the actual sample rate.
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

    /**
        The nominal audio device's sample rate.

        - Returns: *(optional)* A `Float64` value with the nominal sample rate.
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

    /**
        Sets the nominal sample rate.

        - Returns: `true` on success, `false` otherwise.
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

    /**
        A list of all the nominal sample rates supported by this audio device.

        - Returns: *(optional)* A `Float64` array containing the nominal sample rates.
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

    // MARK: - 𝍄 Clock Source Methods

    /**
        The clock source name for the channel number and direction specified.

        - Returns: *(optional)* A `String` containing the clock source name.
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

    /**
        A list of clock source names for the channel number and direction specified.

        - Returns: *(optional)* A `String` array containing all the clock source names.
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

    /**
        Sets the clock source for a channel and direction.

        - Returns: `true` on success, `false` otherwise.
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

    // MARK: - ↹ Latency Methods

    /**
        The latency in frames for the specified direction.

        - Returns: *(optional)* A `UInt32` value with the latency in frames.
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

    /**
        The safety offset frames for the specified direction.

        - Returns: *(optional)* A `UInt32` value with the safety offset in frames.
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

    // MARK: - 🐗 Hog Mode Methods

    /**
        Indicates the `pid` that currently owns exclusive access to the audio device or
        a value of `-1` indicating that the device is currently available to all processes.

        - Returns: *(optional)* A `pid_t` value.
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

    /**
        Attempts to set the `pid` that currently owns exclusive access to the
        audio device.

        - Returns: `true` on success, `false` otherwise.
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

    /**
        Attempts to set the `pid` that currently owns exclusive access to the
        audio device to the current process.

        - Returns: `true` on success, `false` otherwise.
    */
    public func setHogModePidToCurrentProcess() -> Bool {
        let currentPID = pid_t(NSProcessInfo.processInfo().processIdentifier)
        return setHogModePID(currentPID)
    }

    /**
        Attempts to make the audio device available to all processes by setting
        the hog mode to `-1`.

        - Returns: `true` on success, `false` otherwise.
    */
    public func unsetHogMode() -> Bool {
        return setHogModePID(pid_t(-1))
    }

    // MARK: - ♺ Volume Conversion Methods

    /**
        Converts a scalar volume to a decibel *(dbFS)* volume
        for the given channel and direction.

        - Returns: *(optional)* A `Float32` value with the scalar volume converted in decibels.
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

    /**
        Converts a relative decibel *(dbFS)* volume to a scalar volume
        for the given channel and direction.

        - Returns: *(optional)* A `Float32` value with the decibels volume converted to scalar.
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
