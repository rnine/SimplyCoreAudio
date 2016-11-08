//
//  AMAudioDevice.swift
//  AMCoreAudio
//
//  Created by Ruben on 7/7/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation
import AudioToolbox.AudioServices

///// `AMAudioDeviceEvent` enum
public enum AMAudioDeviceEvent: AMEvent {
    /**
        Called whenever the audio device's sample rate changes.
     */
    case nominalSampleRateDidChange(audioDevice: AMAudioDevice)

    /**
        Called whenever the audio device's list of nominal sample rates changes.

        - Note: This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other audio devices (either physical or virtual.)
     */
    case availableNominalSampleRatesDidChange(audioDevice: AMAudioDevice)

    /**
        Called whenever the audio device's clock source changes for a given channel and direction.
     */
    case clockSourceDidChange(audioDevice: AMAudioDevice, channel: UInt32, direction: Direction)

    /**
        Called whenever the audio device's name changes.
     */
    case nameDidChange(audioDevice: AMAudioDevice)

    /**
        Called whenever the list of owned audio devices on this audio device changes.

        - Note: This will typically happen on *Aggregate* and *Multi-Output* devices when adding or removing other audio devices (either physical or virtual.)
     */
    case listDidChange(audioDevice: AMAudioDevice)

    /**
        Called whenever the audio device's volume for a given channel and direction changes.
     */
    case volumeDidChange(audioDevice: AMAudioDevice, channel: UInt32, direction: Direction)

    /**
        Called whenever the audio device's mute state for a given channel and direction changes.
     */
    case muteDidChange(audioDevice: AMAudioDevice, channel:UInt32, direction: Direction)

    /**
        Called whenever the audio device's *is alive* property changes.
     */
    case isAliveDidChange(audioDevice: AMAudioDevice)

    /**
        Called whenever the audio device's *is running* property changes.
     */
    case isRunningDidChange(audioDevice: AMAudioDevice)

    /**
        Called whenever the audio device's *is running somewhere* property changes.
     */
    case isRunningSomewhereDidChange(audioDevice: AMAudioDevice)

    /**
        Called whenever the audio device's *is jack connected* property changes.
     */
    case isJackConnectedDidChange(audioDevice: AMAudioDevice)

    /**
        Called whenever the audio device's *preferred channels for stereo* property changes.
     */
    case preferredChannelsForStereoDidChange(audioDevice: AMAudioDevice)
}

/**
    `AMAudioDevice`

    This class represents an audio device in the system and allows subscribing to audio device notifications.

    Devices may be physical or virtual. For a comprehensive list of supported types, please refer to `TransportType`.
 */
final public class AMAudioDevice: AMAudioObject {
    /**
        The cached device name. This may be useful in some situations where the class instance
        is pointing to a device that is no longer available, so we can still access its name.

        - Returns: The cached device name.
     */
    private(set) var cachedDeviceName: String!

    /**
        The audio device's identifier (ID).

        - Note: This identifier will change with system restarts.
        If you need an unique identifier that persists between restarts, use `deviceUID()` instead.
     
        - SeeAlso: `deviceUID()`

        - Returns: An audio device identifier.
     */
    public var id: AudioObjectID {
        get {
            return objectID
        }
    }

    private var isRegisteredForNotifications = false

    private lazy var notificationsQueue: DispatchQueue = {
        return DispatchQueue(label: "io.9labs.AMCoreAudio.notifications", attributes: .concurrent)
    }()

    private lazy var propertyListenerBlock: AudioObjectPropertyListenerBlock = { [weak self] (inNumberAddresses, inAddresses) -> Void in
        let address = inAddresses.pointee
        let notificationCenter = AMNotificationCenter.defaultCenter

        switch address.mSelector {
        case kAudioDevicePropertyNominalSampleRate:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.nominalSampleRateDidChange(audioDevice: strongSelf))
            }
        case kAudioDevicePropertyAvailableNominalSampleRates:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.availableNominalSampleRatesDidChange(audioDevice: strongSelf))
            }
        case kAudioDevicePropertyClockSource:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.clockSourceDidChange(
                    audioDevice: strongSelf,
                    channel: address.mElement,
                    direction: strongSelf.scopeToDirection(address.mScope)
                ))
            }
        case kAudioObjectPropertyName:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.nameDidChange(audioDevice: strongSelf))
            }
        case kAudioObjectPropertyOwnedObjects:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.listDidChange(audioDevice: strongSelf))
            }
        case kAudioDevicePropertyVolumeScalar:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.volumeDidChange(
                    audioDevice: strongSelf,
                    channel: address.mElement,
                    direction: strongSelf.scopeToDirection(address.mScope)
                ))
            }
        case kAudioDevicePropertyMute:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.muteDidChange(
                    audioDevice: strongSelf,
                    channel: address.mElement,
                    direction: strongSelf.scopeToDirection(address.mScope)
                ))
            }
        case kAudioDevicePropertyDeviceIsAlive:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.isAliveDidChange(audioDevice: strongSelf))
            }
        case kAudioDevicePropertyDeviceIsRunning:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.isRunningDidChange(audioDevice: strongSelf))
            }
        case kAudioDevicePropertyDeviceIsRunningSomewhere:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.isRunningSomewhereDidChange(audioDevice: strongSelf))
            }
        case kAudioDevicePropertyJackIsConnected:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.isJackConnectedDidChange(audioDevice: strongSelf))
            }
        case kAudioDevicePropertyPreferredChannelsForStereo:
            if let strongSelf = self {
                notificationCenter.publish(AMAudioDeviceEvent.preferredChannelsForStereoDidChange(audioDevice: strongSelf))
            }
        // Unhandled cases beyond this point
        case kAudioDevicePropertyBufferFrameSize:
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
        Returns an `AMAudioDevice` by providing a valid audio device identifier.

         - Note: If identifier is not valid, `nil` will be returned.
     */
    public static func lookupByID(_ ID: AudioObjectID) -> AMAudioDevice? {
        var instance = AMAudioObjectPool.instancePool.object(forKey: NSNumber(value: UInt(ID))) as? AMAudioDevice

        if instance == nil {
            instance = AMAudioDevice(deviceID: ID)
        }

        return instance
    }

    /**
        Returns an `AMAudioDevice` by providing a valid audio device unique identifier.

        - Note: If unique identifier is not valid, `nil` will be returned.
     */
    public static func lookupByUID(_ deviceUID: String) -> AMAudioDevice? {
        var deviceID = kAudioObjectUnknown
        let status = AMAudioHardwarePropertyDeviceForUID(deviceUID, &deviceID)

        if noErr != status || deviceID == kAudioObjectUnknown {
            return nil
        }

        return lookupByID(deviceID)
    }

    /**
        Initializes an `AMAudioDevice` by providing an audio device identifier.
     
        - Parameter deviceID: An audio device identifier that is valid and present in the system.
     */
    private init?(deviceID: AudioObjectID) {
        super.init(objectID: deviceID)

        if isAlive() == false {
            return nil
        }

        cachedDeviceName = getDeviceName()
        registerForNotifications()
        AMAudioObjectPool.instancePool.setObject(self, forKey: NSNumber(value: UInt(objectID)))
    }

    deinit {
        unregisterForNotifications()
        AMAudioObjectPool.instancePool.removeObject(forKey: NSNumber(value: UInt(objectID)))
    }

    /**
        Promotes this device to become the default input device.

        - Returns: `true` on success, `false` otherwise.
     */
    public func setAsDefaultInputDevice() -> Bool {
        return setDefaultDevice(kAudioHardwarePropertyDefaultInputDevice)
    }

    /**
        Promotes this device to become the default output device.

        - Returns: `true` on success, `false` otherwise.
     */
    public func setAsDefaultOutputDevice() -> Bool {
        return setDefaultDevice(kAudioHardwarePropertyDefaultOutputDevice)
    }

    /**
        Promotes this device to become the default system output device.

        - Returns: `true` on success, `false` otherwise.
     */
    public func setAsDefaultSystemDevice() -> Bool {
        return setDefaultDevice(kAudioHardwarePropertyDefaultSystemOutputDevice)
    }

    // MARK: - Class Functions

    /**
        All the audio device identifiers currently available in the system.
        
        - Note: This list may also include *Aggregate* and *Multi-Output* devices.

        - Returns: An array of `AudioObjectID` values.
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
        All the audio devices currently available in the system.
        
        - Note: This list may also include *Aggregate* and *Multi-Output* devices.

        - Returns: An array of `AMAudioDevice` objects.
     */
    public class func allDevices() -> [AMAudioDevice] {
        let deviceIDs = allDeviceIDs()

        let devices = deviceIDs.map { deviceID -> AMAudioDevice? in
            AMAudioDevice.lookupByID(deviceID)
        }.flatMap { $0 }

        return devices
    }

    /**
        All the devices in the system that have at least one input.
        
        - Note: This list may also include *Aggregate* devices.

        - Returns: An array of `AMAudioDevice` objects.
     */
    public class func allInputDevices() -> [AMAudioDevice] {
        let devices = allDevices()

        return devices.filter { device -> Bool in
            device.channels(direction: .Recording) > 0
        }
    }

    /**
        All the devices in the system that have at least one output.
        
        - Note: The list may also include *Aggregate* and *Multi-Output* devices.

        - Returns: An array of `AMAudioDevice` objects.
     */
    public class func allOutputDevices() -> [AMAudioDevice] {
        let devices = allDevices()

        return devices.filter { device -> Bool in
            device.channels(direction: .Playback) > 0
        }
    }

    /**
        The default input device.

        - Returns: *(optional)* An `AMAudioDevice`.
     */
    public class func defaultInputDevice() -> AMAudioDevice? {
        return defaultDeviceOfType(kAudioHardwarePropertyDefaultInputDevice)
    }

    /**
        The default output device.

        - Returns: *(optional)* An `AMAudioDevice`.
     */
    public class func defaultOutputDevice() -> AMAudioDevice? {
        return defaultDeviceOfType(kAudioHardwarePropertyDefaultOutputDevice)
    }

    /**
        The default system output device.

        - Returns: *(optional)* An `AMAudioDevice`.
     */
    public class func defaultSystemOutputDevice() -> AMAudioDevice? {
        return defaultDeviceOfType(kAudioHardwarePropertyDefaultSystemOutputDevice)
    }

    // MARK: - ✪ General Device Information Functions

    /**
        The audio device's name as reported by the system.

        - Returns: An audio device's name.
     */
    public override var name: String {
        return getDeviceName()
    }

    /**
        The audio device's unique identifier (UID).

        - Note: This identifier is guaranted to uniquely identify a device in the system
        and will not change even after restarts. Two (or more) identical audio devices
        are also guaranteed to have unique identifiers.

        - SeeAlso: `id`

        - Returns: *(optional)* A `String` with the audio device `UID`.
     */
    public var uid: String? {
        if let address = validAddress(selector: kAudioDevicePropertyDeviceUID) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        The audio device's model unique identifier.

        - Returns: *(optional)* A `String` with the audio device's model unique identifier.
     */
    public var modelUID: String? {
        if let address = validAddress(selector: kAudioDevicePropertyModelUID) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }
    
    /**
        The audio device's manufacturer.

        - Returns: *(optional)* A `String` with the audio device's manufacturer name.
     */
    public var manufacturer: String? {
        if let address = validAddress(selector: kAudioObjectPropertyManufacturer) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        The bundle identifier for an application that provides a GUI for configuring the AudioDevice.
        By default, the value of this property is the bundle ID for *Audio MIDI Setup*.

        - Returns: *(optional)* A `String` pointing to the bundle identifier
     */
    public var configurationApplication: String? {
        if let address = validAddress(selector: kAudioDevicePropertyConfigurationApplication) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        A transport type that indicates how the audio device is connected to the CPU.

        - Returns: *(optional)* A `TransportType`.
     */
    public var transportType: TransportType? {
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
        Whether the audio device is included in the normal list of devices.
        
        - Note: Hidden devices can only be discovered by knowing their `UID` and
        using `kAudioHardwarePropertyDeviceForUID`.

        - Returns: `true` when device is hidden, `false` otherwise.
     */
    public func isHidden() -> Bool {
        if let address = validAddress(selector: kAudioDevicePropertyIsHidden) {
            return getProperty(address: address) ?? false
        } else {
            return false
        }
    }

    /**
         Whether the audio device's jack is connected for a given direction.

         - Returns: `true` when jack is connected, `false` otherwise.
     */
    public func isJackConnected(direction: Direction) -> Bool? {
        if let address = validAddress(selector: kAudioDevicePropertyJackIsConnected,
                                      scope: directionToScope(direction)) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        Whether the device is alive.

        - Returns: `true` when the device is alive, `false` otherwise.
     */
    public func isAlive() -> Bool {
        if let address = validAddress(selector: kAudioDevicePropertyDeviceIsAlive) {
            return getProperty(address: address) ?? false
        } else {
            return false
        }
    }

    /**
        Whether the device is running.

        - Returns: `true` when the device is running, `false` otherwise.
     */
    public func isRunning() -> Bool {
        if let address = validAddress(selector: kAudioDevicePropertyDeviceIsRunning) {
            return getProperty(address: address) ?? false
        } else {
            return false
        }
    }

    /**
        Whether the device is running somewhere.

        - Returns: `true` when the device is running somewhere, `false` otherwise.
     */
    public func isRunningSomewhere() -> Bool {
        if let address = validAddress(selector: kAudioDevicePropertyDeviceIsRunningSomewhere) {
            return getProperty(address: address) ?? false
        } else {
            return false
        }
    }

    /**
        A human readable name for the channel number and direction specified.

        - Returns: *(optional)* A `String` with the name of the channel.
     */
    public func name(channel: UInt32, direction: Direction) -> String? {
        if let address = validAddress(selector: kAudioObjectPropertyElementName,
                                      scope: directionToScope(direction),
                                      element: channel) {
            if let name: String = getProperty(address: address) {
                return name.isEmpty ? nil : name
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    /**
        All the audio object identifiers that are owned by this audio device.
    
         - Returns: *(optional)* An array of `AudioObjectID` values.
    */
    public func ownedObjectIDs() -> [AudioObjectID]? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyOwnedObjects,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var qualifierData = [kAudioObjectClassID]
        let qualifierDataSize = UInt32(MemoryLayout<AudioClassID>.size * qualifierData.count)
        var ownedObjects = [AudioObjectID]()

        let status = getPropertyDataArray(address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &ownedObjects, andDefaultValue: AudioObjectID())

        return noErr == status ? ownedObjects : nil
    }

    /**
        All the audio object identifiers representing the audio controls of this audio device.

        - Returns: *(optional)* An array of `AudioObjectID` values.
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
        All the audio devices related to this audio device.
    
        - Returns: *(optional)* An array of `AMAudioDevice` objects.
     */
    public func relatedDevices() -> [AMAudioDevice]? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyRelatedDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var relatedDevices = [AudioDeviceID]()
        let status = getPropertyDataArray(address, value: &relatedDevices, andDefaultValue: AudioDeviceID())

        if noErr == status {
            return relatedDevices.map { deviceID -> AMAudioDevice? in
                AMAudioDevice.lookupByID(deviceID)
            }.flatMap { $0 }
        }

        return nil
    }

    // MARK: - 💣 LFE (Low Frequency Effects) Functions

    /**
        Whether the audio device should claim ownership of any attached iSub or not.

        - Return: *(optional)* `true` when device should claim ownership, `false` otherwise.
     */
    public var shouldOwniSub: Bool? {
        get {
            if let address = validAddress(selector: kAudioDevicePropertyDriverShouldOwniSub) {
                return getProperty(address: address)
            } else {
                return nil
            }
        }

        set {
            if let address = validAddress(selector: kAudioDevicePropertyDriverShouldOwniSub) {
                if let value = newValue {
                    let _ = setProperty(address: address, value: value)
                }
            }
        }
    }

    /**
        Whether the audio device's LFE (Low Frequency Effects) output is muted or not.

        - Return: *(optional)* `true` when LFE output is muted, `false` otherwise.
     */
    public var LFEMute: Bool? {
        get {
            if let address = validAddress(selector: kAudioDevicePropertySubMute) {
                return getProperty(address: address)
            } else {
                return nil
            }
        }

        set {
            if let address = validAddress(selector: kAudioDevicePropertySubMute) {
                if let value = newValue {
                    let _ = setProperty(address: address, value: value)
                }
            }
        }
    }

    /**
        The audio device's LFE (Low Frequency Effects) scalar output volume.

        - Return: *(optional)* A `Float32` with the volume.
     */
    public var LFEVolume: Float32? {
        get {
            if let address = validAddress(selector: kAudioDevicePropertySubVolumeScalar) {
                return getProperty(address: address)
            } else {
                return nil
            }
        }

        set {
            if let address = validAddress(selector: kAudioDevicePropertySubVolumeScalar) {
                if let value = newValue {
                    let _ = setProperty(address: address, value: value)
                }
            }
        }
    }

    /**
        The audio device's LFE (Low Frequency Effects) output volume in decibels.

        - Return: *(optional)* A `Float32` with the volume.
     */
    public var LFEVolumeDecibels: Float32? {
        get {
            if let address = validAddress(selector: kAudioDevicePropertySubVolumeDecibels) {
                return getProperty(address: address)
            } else {
                return nil
            }
        }

        set {
            if let address = validAddress(selector: kAudioDevicePropertySubVolumeDecibels) {
                if let value = newValue {
                    let _ = setProperty(address: address, value: value)
                }
            }
        }
    }

    // MARK: - ⇄ Input/Output Layout Functions

    /**
        The number of layout channels for a given direction.

        - Returns: *(optional)* A `UInt32` with the number of layout channels.
     */
    public func layoutChannels(direction: Direction) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelLayout,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        if AudioObjectHasProperty(id, &address) {
            var result = AudioChannelLayout()
            let status = getPropertyData(address, andValue: &result)

            return noErr == status ? result.mNumberChannelDescriptions : nil
        }

        return nil
    }

    /**
        The number of channels for a given direction.

        - Returns: A `UInt32` with the number of channels.
     */
    public func channels(direction: Direction) -> UInt32 {
        if let streams = streams(direction: direction) {
            return streams.map({ (stream) -> UInt32 in
                stream.physicalFormat?.mChannelsPerFrame ?? 0
            }).reduce(0, +)
        }

        return 0
    }

    /**
        Whether the device has only inputs but no outputs.

        - Returns: `true` when the device is input only, `false` otherwise.
     */
    public func isInputOnlyDevice() -> Bool {
        return channels(direction: .Playback) == 0 && channels(direction: .Recording) > 0
    }

    /**
        Whether the device has only outputs but no inputs.

        - Returns: `true` when the device is output only, `false` otherwise.
     */
    public func isOutputOnlyDevice() -> Bool {
        return channels(direction: .Recording) == 0 && channels(direction: .Playback) > 0
    }

    // MARK: - ⇉ Individual Channel Functions

    /**
        A `VolumeInfo` struct containing information about a particular channel and direction combination.

        - Returns: *(optional)* A `VolumeInfo` struct.
     */
    public func volumeInfo(channel: UInt32, direction: Direction) -> VolumeInfo? {
        // obtain volume info
        var address: AudioObjectPropertyAddress
        var hasAnyProperty = false

        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: directionToScope(direction),
            mElement: channel
        )

        var volumeInfo = VolumeInfo()

        if AudioObjectHasProperty(id, &address) {
            var canSetVolumeBoolean = DarwinBoolean(false)
            var status = AudioObjectIsPropertySettable(id, &address, &canSetVolumeBoolean)

            if noErr == status {
                volumeInfo.canSetVolume = canSetVolumeBoolean.boolValue
                volumeInfo.hasVolume = true

                var volume = Float32(0)
                status = getPropertyData(address, andValue: &volume)

                if noErr == status {
                    volumeInfo.volume = volume
                    hasAnyProperty = true
                }
            }
        }

        // obtain mute info
        address.mSelector = kAudioDevicePropertyMute

        if AudioObjectHasProperty(id, &address) {
            var canMuteBoolean = DarwinBoolean(false)
            var status = AudioObjectIsPropertySettable(id, &address, &canMuteBoolean)

            if noErr == status {
                volumeInfo.canMute = canMuteBoolean.boolValue

                var isMutedValue = UInt32(0)
                status = getPropertyData(address, andValue: &isMutedValue)

                if noErr == status {
                    volumeInfo.isMuted = Bool(isMutedValue)
                    hasAnyProperty = true
                }
            }
        }

        // obtain play thru info
        address.mSelector = kAudioDevicePropertyPlayThru

        if AudioObjectHasProperty(id, &address) {
            var canPlayThruBoolean = DarwinBoolean(false)
            var status = AudioObjectIsPropertySettable(id, &address, &canPlayThruBoolean)

            if noErr == status {
                volumeInfo.canPlayThru = canPlayThruBoolean.boolValue

                var isPlayThruSetValue = UInt32(0)
                status = getPropertyData(address, andValue: &isPlayThruSetValue)

                if noErr == status {
                    volumeInfo.isPlayThruSet = Bool(isPlayThruSetValue)
                    hasAnyProperty = true
                }
            }
        }

        return hasAnyProperty ? volumeInfo : nil
    }

    /**
        The scalar volume for a given channel and direction.

        - Returns: *(optional)* A `Float32` value with the scalar volume.
     */
    public func volume(channel: UInt32, direction: Direction) -> Float32? {
        if let address = validAddress(selector: kAudioDevicePropertyVolumeScalar,
                                      scope: directionToScope(direction),
                                      element: channel) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        The volume in decibels *(dbFS)* for a given channel and direction.

        - Returns: *(optional)* A `Float32` value with the volume in decibels.
     */
    public func volumeInDecibels(channel: UInt32, direction: Direction) -> Float32? {
        if let address = validAddress(selector: kAudioDevicePropertyVolumeDecibels,
                                      scope: directionToScope(direction),
                                      element: channel) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        Sets the channel's volume for a given direction.

        - Returns: `true` on success, `false` otherwise.
     */
    public func setVolume(_ volume: Float32, channel: UInt32, direction: Direction) -> Bool {
        if let address = validAddress(selector: kAudioDevicePropertyVolumeScalar,
                                      scope: directionToScope(direction),
                                      element: channel) {
            return setProperty(address: address, value: volume)
        } else {
            return false
        }
    }

    /**
        Mutes a channel for a given direction.

        - Returns: `true` on success, `false` otherwise.
     */
    public func setMute(_ shouldMute: Bool, channel: UInt32, direction: Direction) -> Bool {
        if let address = validAddress(selector: kAudioDevicePropertyMute,
                                      scope: directionToScope(direction),
                                      element: channel) {
            return setProperty(address: address, value: shouldMute)
        } else {
            return false
        }
    }

    /**
        Whether a channel is muted for a given direction.

        - Returns: *(optional)* `true` if channel is muted, false otherwise.
     */
    public func isMuted(channel: UInt32, direction: Direction) -> Bool? {
        if let address = validAddress(selector: kAudioDevicePropertyMute,
                                      scope: directionToScope(direction),
                                      element: channel) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        Whether a channel can be muted for a given direction.

        - Returns: `true` if channel can be muted, `false` otherwise.
     */
    public func canMute(channel: UInt32, direction: Direction) -> Bool {
        return volumeInfo(channel: channel, direction: direction)?.canMute ?? false
    }

    /**
        Whether a channel's volume can be set for a given direction.

        - Returns: `true` if the channel's volume can be set, `false` otherwise.
     */
    public func canSetVolume(channel: UInt32, direction: Direction) -> Bool {
        return volumeInfo(channel: channel, direction: direction)?.canSetVolume ?? false
    }

    /**
        A list of channel numbers that best represent the preferred stereo channels
        used by this device. In most occasions this will be channels 1 and 2.

        - Returns: A `StereoPair` tuple containing the channel numbers.
     */
    public func preferredChannelsForStereo(direction: Direction) -> StereoPair? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var preferredChannels = [UInt32]()
        let status = getPropertyDataArray(address, value: &preferredChannels, andDefaultValue: 0)

        if noErr == status && preferredChannels.count == 2 {
            return (left: preferredChannels[0], right: preferredChannels[1])
        } else {
            return nil
        }
    }

    /**
        Attempts to set the new preferred channels for stereo for a given direction.
     
        - Returns: `true` on success, `false` otherwise.
     */
    public func setPreferredChannelsForStereo(channels: StereoPair, direction: Direction) -> Bool {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        var preferredChannels = [channels.left, channels.right]
        let status = setPropertyData(address, andValue: &preferredChannels)

        return noErr == status
    }

    // MARK: - 🔊 Master Volume/Balance Functions

    /**
        Whether the master volume can be muted for a given direction.

        - Returns: `true` when the volume can be muted, `false` otherwise.
     */
    public func canMuteVirtualMasterChannel(direction: Direction) -> Bool {
        if canMute(channel: kAudioObjectPropertyElementMaster, direction: direction) == true {
            return true
        }

        if let preferredChannelsForStereo = preferredChannelsForStereo(direction: direction) {
            if canMute(channel: preferredChannelsForStereo.0, direction: direction) && canMute(channel: preferredChannelsForStereo.1, direction: direction) {
                return true
            }
        }

        return false
    }

    /**
        Whether the master volume can be set for a given direction.

        - Returns: `true` when the volume can be set, `false` otherwise.
     */
    public func canSetVirtualMasterVolume(direction: Direction) -> Bool {
        if validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                                      scope: directionToScope(direction)) != nil {
            return true
        } else {
            return false
        }
    }

    /**
        Sets the virtual master volume for a given direction.

        - Note: The volume is given as a scalar value (i.e., 0 to 1)

        - Returns: `true` on success, `false` otherwise.
     */
    public func setVirtualMasterVolume(_ volume: Float32, direction: Direction) -> Bool {
        if let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                                      scope: directionToScope(direction)) {
            return setProperty(address: address, value: volume)
        } else {
            return false
        }
    }

    /**
        The virtual master scalar volume for a given direction.

        - Returns: *(optional)* A `Float32` value with the scalar volume.
     */
    public func virtualMasterVolume(direction: Direction) -> Float32? {
        if let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                                      scope: directionToScope(direction)) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        The virtual master volume in decibels for a given direction.

        - Returns: *(optional)* A `Float32` value with the volume in decibels.
     */
    public func virtualMasterVolumeInDecibels(direction: Direction) -> Float32? {
        var referenceChannel: UInt32

        if canSetVolume(channel: kAudioObjectPropertyElementMaster, direction: direction) {
            referenceChannel = kAudioObjectPropertyElementMaster
        } else {
            if let channels = preferredChannelsForStereo(direction: direction) {
                referenceChannel = channels.0
            } else {
                return nil
            }
        }

        if let masterVolume = virtualMasterVolume(direction: direction) {
            return scalarToDecibels(volume: masterVolume, channel: referenceChannel, direction: direction)
        } else {
            return nil
        }
    }

    /**
        Whether the volume is muted for a given direction.

        - Returns: `true` when muted, `false` otherwise.
     */
    public func isMasterChannelMuted(direction: Direction) -> Bool? {
        return isMuted(channel: kAudioObjectPropertyElementMaster, direction: direction)
    }

    public func virtualMasterBalance(direction: Direction) -> Float32? {
        if let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterBalance,
                                      scope: directionToScope(direction)) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    public func setVirtualMasterBalance(_ value: Float32, direction: Direction) -> Bool {
        if let address = validAddress(selector: kAudioHardwareServiceDeviceProperty_VirtualMasterBalance,
                                      scope: directionToScope(direction)) {
            return setProperty(address: address, value: value)
        } else {
            return false
        }
    }

    // MARK: - 〰 Sample Rate Functions

    /**
        The actual audio device's sample rate.

        - Returns: *(optional)* A `Float64` value with the actual sample rate.
     */
    public func actualSampleRate() -> Float64? {
        if let address = validAddress(selector: kAudioDevicePropertyActualSampleRate) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        The nominal audio device's sample rate.

        - Returns: *(optional)* A `Float64` value with the nominal sample rate.
     */
    public func nominalSampleRate() -> Float64? {
        if let address = validAddress(selector: kAudioDevicePropertyNominalSampleRate) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        Sets the nominal sample rate.

        - Returns: `true` on success, `false` otherwise.
     */
    public func setNominalSampleRate(_ sampleRate: Float64) -> Bool {
        if let address = validAddress(selector: kAudioDevicePropertyNominalSampleRate) {
            return setProperty(address: address, value: sampleRate)
        } else {
            return false
        }
    }

    /**
        A list of all the nominal sample rates supported by this audio device.

        - Returns: *(optional)* A `Float64` array containing the nominal sample rates.
     */
    public func nominalSampleRates() -> [Float64]? {
        guard let address = validAddress(selector: kAudioDevicePropertyAvailableNominalSampleRates,
                                         scope: kAudioObjectPropertyScopeWildcard) else {
            return nil
        }

        var sampleRates = [Float64]()
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
                if let startIndex = possibleRates.index(of: valueRange.mMinimum),
                    let endIndex = possibleRates.index(of: valueRange.mMaximum) {
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

    // MARK: - 𝍄 Clock Source Functions

    /**
        The clock source identifier for the channel number and direction specified.

        - Returns: *(optional)* A `UInt32` containing the clock source identifier.
     */
    public func clockSourceID(channel: UInt32, direction: Direction) -> UInt32? {
        if let address = validAddress(selector: kAudioDevicePropertyClockSource,
                                      scope: directionToScope(direction)) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        The clock source name for the channel number and direction specified.

        - Returns: *(optional)* A `String` containing the clock source name.
     */
    public func clockSourceName(channel: UInt32, direction: Direction) -> String? {
        if let sourceID = clockSourceID(channel: channel, direction: direction) {
            return clockSourceName(clockSourceID: sourceID)
        }

        return nil
    }

    /**
        A list of clock source identifiers for the channel number and direction specified.

        - Returns: *(optional)* A `UInt32` array containing all the clock source identifiers.
     */
    public func clockSourceIDs(channel: UInt32, direction: Direction) -> [UInt32]? {
        guard let address = validAddress(selector: kAudioDevicePropertyClockSources,
                                         scope: directionToScope(direction),
                                         element: channel) else {
            return nil
        }

        var clockSourceIDs = [UInt32]()
        let status = getPropertyDataArray(address, value: &clockSourceIDs, andDefaultValue: 0)

        if noErr != status {
            return nil
        }

        return clockSourceIDs
    }

    /**
        A list of clock source names for the channel number and direction specified.

        - Returns: *(optional)* A `String` array containing all the clock source names.
     */
    public func clockSourceNames(channel: UInt32, direction: Direction) -> [String]? {
        if let clockSourceIDs = clockSourceIDs(channel: channel, direction: direction) {
            return clockSourceIDs.map { (clockSourceID) -> String in
                // We expect clockSourceNameForClockSourceID to never fail in this case, 
                // but in the unlikely case it does, we provide a default value.
                clockSourceName(clockSourceID: clockSourceID) ?? "Clock source \(clockSourceID)"
            }
        }

        return nil
    }

    /**
        Returns the clock source name for a given clock source ID in a given channel and direction.
     
        - Returns: *(optional)* A `String` with the source clock name.
     */
    public func clockSourceName(clockSourceID: UInt32) -> String? {
        var name: CFString = "" as CFString
        var theClockSourceID = clockSourceID

        var translation = AudioValueTranslation(
            mInputData: &theClockSourceID,
            mInputDataSize: UInt32(MemoryLayout<UInt32>.size),
            mOutputData: &name,
            mOutputDataSize: UInt32(MemoryLayout<CFString>.size)
        )

        let address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyClockSourceNameForIDCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        let status = getPropertyData(address, andValue: &translation)

        return noErr == status ? (name as String) : nil
    }

    /**
        Sets the clock source for a channel and direction.

        - Returns: `true` on success, `false` otherwise.
     */
    public func setClockSourceID(_ clockSourceID: UInt32, channel: UInt32, direction: Direction) -> Bool {
        if let address = validAddress(selector: kAudioDevicePropertyClockSource,
                                      scope: directionToScope(direction),
                                      element: channel) {
            return setProperty(address: address, value: clockSourceID)
        } else {
            return false
        }
    }

    // MARK: - ↹ Latency Functions

    /**
        The latency in frames for the specified direction.

        - Returns: *(optional)* A `UInt32` value with the latency in frames.
     */
    public func deviceLatencyFrames(direction: Direction) -> UInt32? {
        if let address = validAddress(selector: kAudioDevicePropertyLatency,
                                      scope: directionToScope(direction)) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    /**
        The safety offset frames for the specified direction.

        - Returns: *(optional)* A `UInt32` value with the safety offset in frames.
     */
    public func deviceSafetyOffsetFrames(direction: Direction) -> UInt32? {
        if let address = validAddress(selector: kAudioDevicePropertySafetyOffset,
                                      scope: directionToScope(direction)) {
            return getProperty(address: address)
        } else {
            return nil
        }
    }

    // MARK: - 🐗 Hog Mode Functions

    /**
        Indicates the `pid` that currently owns exclusive access to the audio device or
        a value of `-1` indicating that the device is currently available to all processes.

        - Returns: *(optional)* A `pid_t` value.
     */
    public func hogModePID() -> pid_t? {
        guard let address = validAddress(selector: kAudioDevicePropertyHogMode,
                                         scope: kAudioObjectPropertyScopeWildcard) else {
            return nil
        }

        var pid = pid_t()
        let status = getPropertyData(address, andValue: &pid)

        return noErr == status ? pid : nil
    }

    /**
        Toggles hog mode on/off

        - Returns: `true` on success, `false` otherwise.
     */
    private func toggleHogMode() -> Bool {
        if let address = validAddress(selector: kAudioDevicePropertyHogMode,
                                      scope: kAudioObjectPropertyScopeWildcard) {
            return setProperty(address: address, value: 0)
        } else {
            return false
        }
    }

    /**
        Attempts to set the `pid` that currently owns exclusive access to the
        audio device.

        - Returns: `true` on success, `false` otherwise.
     */
    public func setHogMode() -> Bool {
        if hogModePID() != pid_t(ProcessInfo.processInfo.processIdentifier) {
            return toggleHogMode()
        } else {
            return false
        }
    }

    /**
        Attempts to make the audio device available to all processes by setting
        the hog mode to `-1`.

        - Returns: `true` on success, `false` otherwise.
     */
    public func unsetHogMode() -> Bool {
        if hogModePID() == pid_t(ProcessInfo.processInfo.processIdentifier) {
            return toggleHogMode()
        } else {
            return false
        }
    }

    // MARK: - ♺ Volume Conversion Functions

    /**
        Converts a scalar volume to a decibel *(dbFS)* volume
        for the given channel and direction.

        - Returns: *(optional)* A `Float32` value with the scalar volume converted in decibels.
     */
    public func scalarToDecibels(volume: Float32, channel: UInt32, direction: Direction) -> Float32? {
        guard let address = validAddress(selector: kAudioDevicePropertyVolumeScalarToDecibels,
                                      scope: directionToScope(direction),
                                      element: channel) else {
            return nil
        }

        var inOutVolume = volume
        let status = getPropertyData(address, andValue: &inOutVolume)

        return noErr == status ? inOutVolume : nil
    }

    /**
        Converts a relative decibel *(dbFS)* volume to a scalar volume for the given channel and direction.

        - Returns: *(optional)* A `Float32` value with the decibels volume converted to scalar.
     */
    public func decibelsToScalar(volume: Float32, channel: UInt32, direction: Direction) -> Float32? {
        guard let address = validAddress(selector: kAudioDevicePropertyVolumeDecibelsToScalar,
                                         scope: directionToScope(direction),
                                         element: channel) else {
                                            return nil
        }

        var inOutVolume = volume
        let status = getPropertyData(address, andValue: &inOutVolume)

        return noErr == status ? inOutVolume : nil
    }

    // MARK: - ♨︎ Stream Functions

    /**
        Returns a list of streams for a given direction.

        - Returns: *(optional)* An array of `AMAudioStream` objects.
     */
    public func streams(direction: Direction) -> [AMAudioStream]? {
        guard let address = validAddress(selector: kAudioDevicePropertyStreams,
                                         scope: directionToScope(direction)) else {
            return nil
        }

        var streamIDs = [AudioStreamID]()
        let status = getPropertyDataArray(address, value: &streamIDs, andDefaultValue: 0)

        if noErr != status {
            return nil
        }

        return streamIDs.map({ (streamID) -> AMAudioStream in
            AMAudioStream.lookupByID(streamID)!
        })
    }

    // MARK: - Private Functions

    private func setDefaultDevice(_ deviceType: AudioObjectPropertySelector) -> Bool {
        if let address = validAddress(selector: deviceType) {
            return setProperty(address: address, value: UInt32(id))
        } else {
            return false
        }
    }

    private func getDeviceName() -> String {
        return super.name ?? (cachedDeviceName ?? "<Unknown Device Name>")
    }

    private class func defaultDeviceOfType(_ deviceType: AudioObjectPropertySelector) -> AMAudioDevice? {
        let address = AudioObjectPropertyAddress(
            mSelector: deviceType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var deviceID = AudioDeviceID()
        let status = getPropertyData(AudioObjectID(kAudioObjectSystemObject), address: address, andValue: &deviceID)

        return noErr == status ? AMAudioDevice.lookupByID(deviceID) : nil
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

        let err = AudioObjectAddPropertyListenerBlock(id, &address, notificationsQueue, propertyListenerBlock)

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

            let err = AudioObjectRemovePropertyListenerBlock(id, &address, notificationsQueue, propertyListenerBlock)

            if noErr != err {
                print("Error on AudioObjectRemovePropertyListenerBlock: \(err)")
            }

            isRegisteredForNotifications = noErr != err
        } else {
            isRegisteredForNotifications = false
        }
    }
}

extension AMAudioDevice {

    /**
        Returns a string describing this audio device.
     */
    public override var description: String {
        return "\(name) (\(id)) \(super.description)"
    }
}

// MARK: - Deprecated

extension AMAudioDevice {
    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use id instead") public var deviceID: AudioObjectID {
        return id
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use name instead") public func deviceName() -> String {
        return name
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use uid instead") public func deviceUID() -> String? {
        return uid
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use modelUID instead") public func deviceModelUID() -> String? {
        return modelUID
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use configurationApplication instead") public func deviceConfigurationApplication() -> String? {
        return configurationApplication
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use manufacturer instead") public func deviceManufacturer() -> String? {
        return manufacturer
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use isHidden() instead") public func deviceIsHidden() -> Bool {
        return isHidden()
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use streams(direction:) instead") public func streamsForDirection(_ direction: Direction) -> [AMAudioStream]? {
        return streams(direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use channels(direction:) instead") public func channelsForDirection(_ direction: Direction) -> UInt32 {
        return channels(direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use volumeInfo(channel:direction:) instead") public func volumeInfoForChannel(_ channel: UInt32, andDirection direction: Direction) -> VolumeInfo? {
        return volumeInfo(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use canMute(channel:direction:) instead") public func canMuteForChannel(_ channel: UInt32, andDirection direction: Direction) -> Bool {
        return canMute(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use canSetvolume(channel:direction:) instead") public func canSetVolumeForChannel(_ channel: UInt32, andDirection direction: Direction) -> Bool {
        return canSetVolume(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use virtualMasterVolume(direction:) instead") public func masterVolumeForDirection(_ direction: Direction) -> Float32? {
        return virtualMasterVolume(direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use setVirtualMasterVolume(_:direction:) instead") public func setMasterVolume(_ volume: Float32, forDirection direction: Direction) -> Bool {
        return setVirtualMasterVolume(volume, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use virtualMasterVolumeInDecibels(direction:) instead")public func masterVolumeInDecibelsForDirection(_ direction: Direction) -> Float32? {
        return virtualMasterVolumeInDecibels(direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use name(channel:direction:) instead") public func nameForChannel(_ channel: UInt32, andDirection direction: Direction) -> String? {
        return name(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use layoutChannels(direction:) instead") public func layoutChannelsForDirection(_ direction: Direction) -> UInt32? {
        return layoutChannels(direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use volume(channel:direction:) instead") public func volumeForChannel(_ channel: UInt32, andDirection direction: Direction) -> Float32? {
        return volume(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use volumeInDecibels(channel:direction:) instead") public func volumeInDecibelsForChannel(_ channel: UInt32, andDirection direction: Direction) -> Float32? {
        return volumeInDecibels(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use setVolume(_:channel:direction:) instead") public func setVolume(_ volume: Float32, forChannel channel: UInt32, andDirection direction: Direction) -> Bool {
        return setVolume(volume, channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use setMute(_:channel:direction:) instead") public func setMute(_ shouldMute: Bool, forChannel channel: UInt32, andDirection direction: Direction) -> Bool {
        return setMute(shouldMute, channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use isMuted(channel:direction:) instead") public func isChannelMuted(_ channel: UInt32, andDirection direction: Direction) -> Bool? {
        return isMuted(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use isMasterChannelMuted(direction:) instead") public func isMasterVolumeMutedForDirection(_ direction: Direction) -> Bool? {
        return isMasterChannelMuted(direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use preferredChannelsForStereo(direction:) instead") public func preferredStereoChannelsForDirection(_ direction: Direction) -> [UInt32]? {
        if let preferredChannelsForStereo = preferredChannelsForStereo(direction: direction) {
            return [preferredChannelsForStereo.0, preferredChannelsForStereo.1]
        } else {
            return nil
        }
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use canMuteVirtualMasterChannel(direction:) instead") public func canMuteMasterVolumeForDirection(_ direction: Direction) -> Bool {
        return canMuteVirtualMasterChannel(direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use canSetVirtualMasterVolume(direction:) instead") public func canSetMastervolumeForDirection(_ direction: Direction) -> Bool {
        return canSetVirtualMasterVolume(direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use scalarToDecibels(volume:channel:direction:) instead") public func scalarToDecibels(_ volume: Float32, forChannel channel: UInt32, andDirection direction: Direction) -> Float32? {
        return scalarToDecibels(volume: volume, channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use decibelsToScalar(volume:channel:direction:) instead") public func decibelsToScalar(_ volume: Float32, forChannel channel: UInt32, andDirection direction: Direction) -> Float32? {
        return decibelsToScalar(volume: volume, channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use deviceLatencyFrames(direction:) instead") public func deviceLatencyFramesForDirection(_ direction: Direction) -> UInt32? {
        return deviceLatencyFrames(direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use deviceSafetyOffsetFrames(direction:) instead") public func deviceSafetyOffsetFramesForDirection(_ direction: Direction) -> UInt32? {
        return deviceSafetyOffsetFrames(direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use clockSourceID(channel:direction:) instead") public func clockSourceIDForChannel(_ channel: UInt32, andDirection direction: Direction) -> UInt32? {
        return clockSourceID(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use clockSourceName(channel:direction:) instead") public func clockSourceForChannel(_ channel: UInt32, andDirection direction: Direction) -> String? {
        return clockSourceName(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use clockSourceIDs(channel:direction:) instead") public func clockSourceIDsForChannel(_ channel: UInt32, andDirection direction: Direction) -> [UInt32]? {
        return clockSourceIDs(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use clockSourceNames(channel:direction:) instead") public func clockSourcesForChannel(_ channel: UInt32, andDirection direction: Direction) -> [String]? {
        return clockSourceNames(channel: channel, direction: direction)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use clockSourceName(clockSourceID:) instead") public func clockSourceNameForClockSourceID(_ clockSourceID: UInt32, forChannel _: UInt32, andDirection _: Direction) -> String? {
        return clockSourceName(clockSourceID: clockSourceID)
    }

    /// :nodoc:
    @available(*, deprecated, message: "Marked for removal in 3.2. Use setClockSourceID(_:channel:direction:) instead") public func setClockSourceID(_ clockSourceID: UInt32, forChannel channel: UInt32, andDirection direction: Direction) -> Bool {
        return setClockSourceID(clockSourceID, channel: channel, direction: direction)
    }
}
