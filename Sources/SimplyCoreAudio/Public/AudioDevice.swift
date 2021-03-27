//
//  AudioDevice.swift
//
//  Created by Ruben Nine on 7/7/15.
//

import CoreAudio
import Foundation
import os.log

/// This class represents an audio device managed by [Core Audio](https://developer.apple.com/documentation/coreaudio).
///
/// Devices may be physical or virtual. For a comprehensive list of supported types, please refer to `TransportType`.
public final class AudioDevice: AudioObject {
    // MARK: - Static Private Properties

    private static let deviceClassIDs: Set<AudioClassID> = [
        kAudioDeviceClassID,
        kAudioSubDeviceClassID,
        kAudioAggregateDeviceClassID,
        kAudioEndPointClassID,
        kAudioEndPointDeviceClassID
    ]

    // MARK: - Internal Properties

    let hardware = AudioHardware()

    // MARK: - Private Properties

    private var cachedDeviceName: String?
    private var isRegisteredForNotifications = false

    // MARK: - Lifecycle Functions

    /// Initializes an `AudioDevice` by providing a valid audio device identifier.
    ///
    /// - Parameter id: An audio device identifier.
    private init?(id: AudioObjectID) {
        super.init(objectID: id)

        guard let classID = classID, Self.deviceClassIDs.contains(classID) else { return nil }

        AudioObjectPool.shared.set(self, for: objectID)
        registerForNotifications()

        cachedDeviceName = super.name
    }

    deinit {
        AudioObjectPool.shared.remove(objectID)
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
        var instance = AudioObjectPool.shared.get(id) as? AudioDevice

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
    // Ensure audio object is still in the pool, otherwise it probably is (or is in the process of being) deallocated.
    guard AudioObjectPool.shared.get(objectID) != nil else { return kAudioHardwareBadObjectError }

    let _self: AudioDevice = Unmanaged<AudioDevice>.fromOpaque(clientData!).takeUnretainedValue()
    let address = inAddresses.pointee
    let notificationCenter = NotificationCenter.default

    switch address.mSelector {
    case kAudioDevicePropertyNominalSampleRate:
        notificationCenter.post(name: .deviceNominalSampleRateDidChange, object: _self)
    case kAudioDevicePropertyAvailableNominalSampleRates:
        notificationCenter.post(name: .deviceAvailableNominalSampleRatesDidChange, object: _self)
    case kAudioDevicePropertyClockSource:
        notificationCenter.post(name: .deviceClockSourceDidChange, object: _self)
    case kAudioObjectPropertyName:
        notificationCenter.post(name: .deviceNameDidChange, object: _self)
    case kAudioObjectPropertyOwnedObjects:
        notificationCenter.post(name: .deviceOwnedObjectsDidChange, object: _self)
    case kAudioDevicePropertyVolumeScalar:
        let userInfo: [AnyHashable: Any] = [
            "channel": address.mElement,
            "scope": Scope.from(address.mScope)!
        ]

        notificationCenter.post(name: .deviceVolumeDidChange, object: _self, userInfo: userInfo)
    case kAudioDevicePropertyMute:
        let userInfo: [AnyHashable: Any] = [
            "channel": address.mElement,
            "scope": Scope.from(address.mScope)!
        ]

        notificationCenter.post(name: .deviceMuteDidChange, object: _self, userInfo: userInfo)
    case kAudioDevicePropertyDeviceIsAlive:
        notificationCenter.post(name: .deviceIsAliveDidChange, object: _self)
    case kAudioDevicePropertyDeviceIsRunning:
        notificationCenter.post(name: .deviceIsRunningDidChange, object: _self)
    case kAudioDevicePropertyDeviceIsRunningSomewhere:
        notificationCenter.post(name: .deviceIsRunningSomewhereDidChange, object: _self)
    case kAudioDevicePropertyJackIsConnected:
        notificationCenter.post(name: .deviceIsJackConnectedDidChange, object: _self)
    case kAudioDevicePropertyPreferredChannelsForStereo:
        notificationCenter.post(name: .devicePreferredChannelsForStereoDidChange, object: _self)
    case kAudioDevicePropertyHogMode:
        notificationCenter.post(name: .deviceHogModeDidChange, object: _self)
    default:
        break
    }

    return kAudioHardwareNoError
}
