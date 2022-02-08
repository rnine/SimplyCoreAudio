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
        kAudioEndPointDeviceClassID,
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
    override public var name: String { super.name ?? cachedDeviceName ?? "<Unknown Device Name>" }
}

// MARK: - Class Functions

public extension AudioDevice {
    /// Returns an `AudioDevice` by providing a valid audio device identifier.
    ///
    /// - Parameter id: An audio device identifier.
    ///
    /// - Note: If identifier is not valid, `nil` will be returned.
    static func lookup(by id: AudioObjectID) -> AudioDevice? {
        var instance: AudioDevice? = AudioObjectPool.shared.get(id)

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
            mElement: Element.main.asPropertyElement
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

        if noErr != AudioObjectAddPropertyListener(id, &address, propertyListener, nil) {
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

        if noErr != AudioObjectRemovePropertyListener(id, &address, propertyListener, nil) {
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
                              inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
                              clientData: Optional<UnsafeMutableRawPointer>) -> Int32 {
    // Try to get audio object from the pool.
    guard let obj: AudioDevice = AudioObjectPool.shared.get(objectID) else { return kAudioHardwareBadObjectError }

    let address = inAddresses.pointee
    let notificationCenter = NotificationCenter.default

    switch address.mSelector {
    case kAudioDevicePropertyNominalSampleRate:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceNominalSampleRateDidChange, object: obj) }
    case kAudioDevicePropertyAvailableNominalSampleRates:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceAvailableNominalSampleRatesDidChange, object: obj) }
    case kAudioDevicePropertyClockSource:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceClockSourceDidChange, object: obj) }
    case kAudioObjectPropertyName:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceNameDidChange, object: obj) }
    case kAudioObjectPropertyOwnedObjects:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceOwnedObjectsDidChange, object: obj) }
    case kAudioDevicePropertyVolumeScalar:
        let userInfo: [AnyHashable: Any] = [
            "channel": address.mElement,
            "scope": Scope.from(address.mScope),
        ]

        DispatchQueue.main.async { notificationCenter.post(name: .deviceVolumeDidChange, object: obj, userInfo: userInfo) }
    case kAudioDevicePropertyMute:
        let userInfo: [AnyHashable: Any] = [
            "channel": address.mElement,
            "scope": Scope.from(address.mScope),
        ]

        DispatchQueue.main.async { notificationCenter.post(name: .deviceMuteDidChange, object: obj, userInfo: userInfo) }
    case kAudioDevicePropertyDeviceIsAlive:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceIsAliveDidChange, object: obj) }
    case kAudioDevicePropertyDeviceIsRunning:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceIsRunningDidChange, object: obj) }
    case kAudioDevicePropertyDeviceIsRunningSomewhere:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceIsRunningSomewhereDidChange, object: obj) }
    case kAudioDevicePropertyJackIsConnected:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceIsJackConnectedDidChange, object: obj) }
    case kAudioDevicePropertyPreferredChannelsForStereo:
        DispatchQueue.main.async { notificationCenter.post(name: .devicePreferredChannelsForStereoDidChange, object: obj) }
    case kAudioDevicePropertyHogMode:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceHogModeDidChange, object: obj) }
    case kAudioDeviceProcessorOverload:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceProcessorOverload, object: obj) }
    case kAudioDevicePropertyIOStoppedAbnormally:
        DispatchQueue.main.async { notificationCenter.post(name: .deviceIOStoppedAbnormally, object: obj) }

    default:
        break
    }

    return kAudioHardwareNoError
}
