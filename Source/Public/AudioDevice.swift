//
//  AudioDevice.swift
//
//  Created by Ruben Nine on 7/7/15.
//

import AudioToolbox.AudioServices
import Foundation
import os.log

/// `AudioDevice` represents an audio device managed by Core Audio.
///
/// Devices may be physical or virtual. For a comprehensive list of supported types, please refer to `TransportType`.
public final class AudioDevice: AudioObject {
    // MARK: - Private Properties

    private var cachedDeviceName: String?
    private var isRegisteredForNotifications = false

    // MARK: - Lifecycle Functions

    /// Initializes an `AudioDevice` by providing a valid audio device identifier.
    ///
    /// - Parameter id: An audio device identifier.
    private init?(id: AudioObjectID) {
        super.init(objectID: id)

        guard owningObject != nil else { return nil }

        cachedDeviceName = super.name
        registerForNotifications()
        AudioObjectPool.instancePool.setObject(self, forKey: NSNumber(value: UInt(objectID)))
    }

    deinit {
        AudioObjectPool.instancePool.removeObject(forKey: NSNumber(value: UInt(objectID)))
        unregisterForNotifications()
    }

    // MARK: - AudioObject Overrides

    /// The audio device's name as reported by Core Audio.
    ///
    /// - Returns: An audio device's name.
    public override var name: String { super.name ?? cachedDeviceName ?? "<Unknown Device Name>" }
}

// MARK: - Class Functions

public extension AudioDevice {
    /// Returns an `AudioDevice` by providing a valid audio device identifier.
    ///
    /// - Parameter id: An audio device identifier.
    ///
    /// - Note: If identifier is not valid, `nil` will be returned.
    static func lookup(by id: AudioObjectID) -> AudioDevice? {
        var instance = AudioObjectPool.instancePool.object(forKey: NSNumber(value: UInt(id))) as? AudioDevice

        if instance == nil {
            instance = AudioDevice(id: id)
        }

        return instance
    }

    /// Returns an `AudioDevice` by providing a valid audio device unique identifier.
    ///
    /// - Parameter uid: An audio device unique identifier.
    ///
    /// - Note: If unique identifier is not valid, `nil` will be returned.
    static func lookup(by uid: String) -> AudioDevice? {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDeviceForUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        var deviceID = kAudioObjectUnknown
        var cfUID = (uid as CFString)

        let status: OSStatus = withUnsafeMutablePointer(to: &cfUID) { cfUIDPtr in
            withUnsafeMutablePointer(to: &deviceID) { deviceIDPtr in
                var translation = AudioValueTranslation(
                    mInputData: cfUIDPtr,
                    mInputDataSize: UInt32(MemoryLayout<CFString>.size),
                    mOutputData: deviceIDPtr,
                    mOutputDataSize: UInt32(MemoryLayout<AudioObjectID>.size)
                )

                return getPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                       address: address,
                                       andValue: &translation)
            }
        }

        if noErr != status || deviceID == kAudioObjectUnknown {
            return nil
        }

        return lookup(by: deviceID)
    }
}

// MARK: - Private Functions

private extension AudioDevice {
    // MARK: - Notification Book-keeping

    func registerForNotifications() {
        if isRegisteredForNotifications {
            unregisterForNotifications()
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        if noErr != AudioObjectAddPropertyListener(id, &address, propertyListener, selfPtr) {
            os_log("Unable to add property listener for %@.", description)
        } else {
            isRegisteredForNotifications = true
        }
    }

    func unregisterForNotifications() {
        guard isRegisteredForNotifications, isAlive else { return }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        if noErr != AudioObjectRemovePropertyListener(id, &address, propertyListener, selfPtr) {
            os_log("Unable to remove property listener for %@.", description)
        } else {
            isRegisteredForNotifications = false
        }
    }
}

// MARK: - CustomStringConvertible Conformance

extension AudioDevice: CustomStringConvertible {
    /// Returns a `String` representation of self.
    public var description: String {
        return "\(name) (\(id))"
    }
}

// MARK: - C Convention Functions

private func propertyListener(objectID: UInt32,
                              numInAddresses: UInt32,
                              inAddresses : UnsafePointer<AudioObjectPropertyAddress>,
                              clientData: Optional<UnsafeMutableRawPointer>) -> Int32 {
    guard AudioObjectPool.instancePool.object(forKey: NSNumber(value: UInt(objectID))) != nil else {
        return kAudioHardwareBadObjectError
    }

    let _self: AudioDevice = Unmanaged<AudioDevice>.fromOpaque(clientData!).takeUnretainedValue()
    let address = inAddresses.pointee
    let notificationCenter = NotificationCenter.default

    switch address.mSelector {
    case kAudioDevicePropertyNominalSampleRate:
        notificationCenter.post(name: Notifications.deviceNominalSampleRateDidChange.name, object: _self)
    case kAudioDevicePropertyAvailableNominalSampleRates:
        notificationCenter.post(name: Notifications.deviceAvailableNominalSampleRatesDidChange.name, object: _self)
    case kAudioDevicePropertyClockSource:
        notificationCenter.post(name: Notifications.deviceClockSourceDidChange.name, object: _self)
    case kAudioObjectPropertyName:
        notificationCenter.post(name: Notifications.deviceNameDidChange.name, object: _self)
    case kAudioObjectPropertyOwnedObjects:
        notificationCenter.post(name: Notifications.deviceOwnedObjectsDidChange.name, object: _self)
    case kAudioDevicePropertyVolumeScalar:
        let userInfo: [AnyHashable: Any] = [
            "channel": address.mElement,
            "scope": scope
        ]

        notificationCenter.post(name: Notifications.deviceVolumeDidChange.name, object: _self, userInfo: userInfo)
    case kAudioDevicePropertyMute:
        let userInfo: [AnyHashable: Any] = [
            "channel": address.mElement,
            "scope": scope
        ]

        notificationCenter.post(name: Notifications.deviceMuteDidChange.name, object: _self, userInfo: userInfo)
    case kAudioDevicePropertyDeviceIsAlive:
        notificationCenter.post(name: Notifications.deviceIsAliveDidChange.name, object: _self)
    case kAudioDevicePropertyDeviceIsRunning:
        notificationCenter.post(name: Notifications.deviceIsRunningDidChange.name, object: _self)
    case kAudioDevicePropertyDeviceIsRunningSomewhere:
        notificationCenter.post(name: Notifications.deviceIsRunningSomewhereDidChange.name, object: _self)
    case kAudioDevicePropertyJackIsConnected:
        notificationCenter.post(name: Notifications.deviceIsJackConnectedDidChange.name, object: _self)
    case kAudioDevicePropertyPreferredChannelsForStereo:
        notificationCenter.post(name: Notifications.devicePreferredChannelsForStereoDidChange.name, object: _self)
    case kAudioDevicePropertyHogMode:
        notificationCenter.post(name: Notifications.deviceHogModeDidChange.name, object: _self)
    default:
        break
    }

    return kAudioHardwareNoError
}
