//
//  AudioStream.swift
//
//  Created by Ruben Nine on 13/04/16.
//

import CoreAudio
import Foundation
import os.log

/// This class represents an audio stream that belongs to an audio object managed by
/// [Core Audio](https://developer.apple.com/documentation/coreaudio).
public final class AudioStream: AudioObject {
    // MARK: - Public Properties

    /// This audio stream's identifier.
    ///
    /// - Returns: An `AudioObjectID`.
    public var id: AudioObjectID { objectID }

    /// Returns whether this audio stream is enabled and doing I/O.
    ///
    /// - Returns: `true` when enabled, `false` otherwise.
    public var active: Bool {
        guard let address = validAddress(selector: kAudioStreamPropertyIsActive) else { return false }

        var active: UInt32 = 0
        guard noErr == getPropertyData(address, andValue: &active) else { return false }

        return active == 1
    }

    /// Specifies the first element in the owning device that corresponds to the element one of this stream.
    ///
    /// - Returns: *(optional)* A `UInt32`.
    public var startingChannel: UInt32? {
        guard let address = validAddress(selector: kAudioStreamPropertyStartingChannel) else { return nil }

        var startingChannel: UInt32 = 0
        guard noErr == self.getPropertyData(address, andValue: &startingChannel) else { return nil }

        return startingChannel
    }

    /// Describes the general kind of functionality attached to this stream.
    ///
    /// - Return: A `TerminalType`.
    public var terminalType: TerminalType {
        guard let address = validAddress(selector: kAudioStreamPropertyTerminalType) else { return .unknown }

        var terminalType: UInt32 = 0
        guard noErr == getPropertyData(address, andValue: &terminalType) else { return .unknown }

        return .from(terminalType)
    }

    /// The latency in frames for this stream.
    ///
    /// Note that the owning `AudioDevice` may have additional latency so it should be
    /// queried as well. If both the device and the stream say they have latency,
    /// then the total latency for the stream is the device latency summed with the
    /// stream latency.
    ///
    /// - Returns: *(optional)* A `UInt32` value with the latency in frames.
    public var latency: UInt32? {
        guard let address = validAddress(selector: kAudioStreamPropertyLatency) else { return nil }

        var latency: UInt32 = 0
        guard noErr == getPropertyData(address, andValue: &latency) else { return nil }

        return latency
    }

    /// The audio stream's scope.
    ///
    /// For output streams, and to continue using the same `Scope` concept used by `AudioDevice`,
    /// this will be `Scope.output`, likewise, for input streams, `Scope.input` will be returned.
    ///
    /// - Returns: *(optional)* A `Scope`.
    public var scope: Scope? {
        guard let address = validAddress(selector: kAudioStreamPropertyDirection) else { return nil }

        var propertyScope: UInt32 = 0
        guard noErr == getPropertyData(address, andValue: &propertyScope) else { return nil }

        switch propertyScope {
        case 0: return .output
        case 1: return .input
        default: return nil
        }
    }

    /// An `AudioStreamBasicDescription` that describes the current data format for this audio stream.
    ///
    /// - SeeAlso: `virtualFormat`
    ///
    /// - Returns: *(optional)* An `AudioStreamBasicDescription`.
    public var physicalFormat: AudioStreamBasicDescription? {
        get {
            var asbd = AudioStreamBasicDescription()
            guard noErr == getStreamPropertyData(kAudioStreamPropertyPhysicalFormat, andValue: &asbd) else { return nil }

            return asbd
        }

        set {
            var asbd = newValue

            if noErr != setStreamPropertyData(kAudioStreamPropertyPhysicalFormat, andValue: &asbd) {
                os_log("Error setting physicalFormat to %@.", log: .default, type: .debug, String(describing: newValue))
            }
        }
    }

    /// An `AudioStreamBasicDescription` that describes the current virtual data format for this audio stream.
    ///
    /// - SeeAlso: `physicalFormat`
    ///
    /// - Returns: *(optional)* An `AudioStreamBasicDescription`.
    public var virtualFormat: AudioStreamBasicDescription? {
        get {
            var asbd = AudioStreamBasicDescription()
            guard noErr == getStreamPropertyData(kAudioStreamPropertyVirtualFormat, andValue: &asbd) else { return nil }

            return asbd
        }

        set {
            var asbd = newValue

            if noErr != setStreamPropertyData(kAudioStreamPropertyVirtualFormat, andValue: &asbd) {
                os_log("Error setting virtualFormat to %@.", log: .default, type: .debug, String(describing: newValue))
            }
        }
    }

    /// All the available physical formats for this audio stream.
    ///
    /// - SeeAlso: `availableVirtualFormats`
    ///
    /// - Returns: *(optional)* An array of `AudioStreamRangedDescription` structs.
    public lazy var availablePhysicalFormats: [AudioStreamRangedDescription]? = {
        guard let scope = scope else { return nil }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyAvailablePhysicalFormats,
            mScope: scope.asPropertyScope,
            mElement: Element.main.asPropertyElement
        )

        guard AudioObjectHasProperty(id, &address) else { return nil }
        var asrd = [AudioStreamRangedDescription]()
        guard noErr == getPropertyDataArray(address, value: &asrd, andDefaultValue: AudioStreamRangedDescription()) else {
            return nil
        }

        return asrd
    }()

    /// All the available virtual formats for this audio stream.
    ///
    /// - SeeAlso: `availablePhysicalFormats`
    ///
    /// - Returns: *(optional)* An array of `AudioStreamRangedDescription` structs.
    public lazy var availableVirtualFormats: [AudioStreamRangedDescription]? = {
        guard let scope = scope else { return nil }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyAvailableVirtualFormats,
            mScope: scope.asPropertyScope,
            mElement: Element.main.asPropertyElement
        )

        guard AudioObjectHasProperty(id, &address) else { return nil }
        var asrd = [AudioStreamRangedDescription]()
        guard noErr == getPropertyDataArray(address, value: &asrd, andDefaultValue: AudioStreamRangedDescription()) else {
            return nil
        }

        return asrd
    }()

    // MARK: - Private Properties

    private var isRegisteredForNotifications = false

    // MARK: - Lifecycle

    /// Initializes an `AudioStream` by providing a valid `AudioObjectID` referencing an existing audio stream.
    private init?(id: AudioObjectID) {
        super.init(objectID: id)

        guard owningObject != nil else { return nil }

        AudioObjectPool.shared.set(self, for: objectID)
        registerForNotifications()
    }

    deinit {
        AudioObjectPool.shared.remove(objectID)
        unregisterForNotifications()
    }
}

// MARK: - Public Functions

public extension AudioStream {
    /// Returns an `AudioStream` by providing a valid audio stream identifier.
    ///
    /// - Note: If identifier is not valid, `nil` will be returned.
    static func lookup(by id: AudioObjectID) -> AudioStream? {
        var instance: AudioStream? = AudioObjectPool.shared.get(id)

        if instance == nil {
            instance = AudioStream(id: id)
        }

        return instance
    }

    /// All the available physical formats for this audio stream matching the current physical format's sample rate.
    ///
    /// - Note: By default, both mixable and non-mixable streams are returned, however,  non-mixable
    /// streams can be filtered out by setting `includeNonMixable` to `false`.
    ///
    /// - Parameter includeNonMixable: Whether to include non-mixable streams in the returned array. Defaults to `true`.
    ///
    /// - SeeAlso: `availableVirtualFormatsMatchingCurrentNominalSampleRate(_:)`
    ///
    /// - Returns: *(optional)* An array of `AudioStreamBasicDescription` structs.
    func availablePhysicalFormatsMatchingCurrentNominalSampleRate(_ includeNonMixable: Bool = true) -> [AudioStreamBasicDescription]? {
        guard let physicalFormats = availablePhysicalFormats, let physicalFormat = physicalFormat else { return nil }

        var filteredFormats = physicalFormats.filter { (format) -> Bool in
            format.mSampleRateRange.mMinimum >= physicalFormat.mSampleRate &&
                format.mSampleRateRange.mMaximum <= physicalFormat.mSampleRate
        }.map { $0.mFormat }

        if !includeNonMixable {
            filteredFormats = filteredFormats.filter { $0.mFormatFlags & kAudioFormatFlagIsNonMixable == 0 }
        }

        return filteredFormats
    }

    /// All the available virtual formats for this audio stream matching the current virtual format's sample rate.
    ///
    /// - Note: By default, both mixable and non-mixable streams are returned, however,  non-mixable
    /// streams can be filtered out by setting `includeNonMixable` to `false`.
    ///
    /// - Parameter includeNonMixable: Whether to include non-mixable streams in the returned array. Defaults to `true`.
    ///
    /// - SeeAlso: `availablePhysicalFormatsMatchingCurrentNominalSampleRate(_:)`
    ///
    /// - Returns: *(optional)* An array of `AudioStreamBasicDescription` structs.
    func availableVirtualFormatsMatchingCurrentNominalSampleRate(_ includeNonMixable: Bool = true) -> [AudioStreamBasicDescription]? {
        guard let virtualFormats = availableVirtualFormats, let virtualFormat = virtualFormat else { return nil }

        var filteredFormats = virtualFormats.filter { (format) -> Bool in
            format.mSampleRateRange.mMinimum >= virtualFormat.mSampleRate &&
                format.mSampleRateRange.mMaximum <= virtualFormat.mSampleRate
        }.map { $0.mFormat }

        if !includeNonMixable {
            filteredFormats = filteredFormats.filter { $0.mFormatFlags & kAudioFormatFlagIsNonMixable == 0 }
        }

        return filteredFormats
    }
}

// MARK: - Private Functions

private extension AudioStream {
    /// This is an specialized version of `getPropertyData` that only requires passing an `AudioObjectPropertySelector`
    /// instead of an `AudioObjectPropertyAddress`. The scope is computed from the stream's `Scope`, and the element
    /// is assumed to be `kAudioObjectPropertyElementMain`.
    ///
    /// Additionally, the property address is validated before calling `getPropertyData`.
    ///
    /// - Parameter selector: The `AudioObjectPropertySelector` that points to the property we want to get.
    /// - Parameter value: The value that will be returned.
    ///
    /// - Returns: An `OSStatus` with `noErr` on success, or an error code other than `noErr` when it fails.
    func getStreamPropertyData<T>(_ selector: AudioObjectPropertySelector, andValue value: inout T) -> OSStatus? {
        guard let scope = scope else { return nil }

        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope.asPropertyScope,
            mElement: Element.main.asPropertyElement
        )

        guard AudioObjectHasProperty(id, &address) else { return nil }

        return getPropertyData(address, andValue: &value)
    }

    /// This is an specialized version of `setPropertyData` that only requires passing an `AudioObjectPropertySelector`
    /// instead of an `AudioObjectPropertyAddress`. The scope is computed from the stream's `Scope`, and the element
    /// is assumed to be `kAudioObjectPropertyElementMain`.
    ///
    /// Additionally, the property address is validated before calling `setPropertyData`.
    ///
    /// - Parameter selector: The `AudioObjectPropertySelector` that points to the property we want to set.
    /// - Parameter value: The new value we want to set.
    ///
    /// - Returns: An `OSStatus` with `noErr` on success, or an error code other than `noErr` when it fails.
    func setStreamPropertyData<T>(_ selector: AudioObjectPropertySelector, andValue value: inout T) -> OSStatus? {
        guard let scope = scope else { return nil }

        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope.asPropertyScope,
            mElement: Element.main.asPropertyElement
        )

        guard AudioObjectHasProperty(id, &address) else { return nil }

        return setPropertyData(address, andValue: &value)
    }

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
        guard isRegisteredForNotifications else { return }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        if noErr != AudioObjectRemovePropertyListener(id, &address, propertyListener, nil) {
            os_log("Unable to add property listener for %@.", description)
        } else {
            isRegisteredForNotifications = true
        }
    }
}

// MARK: - CustomStringConvertible Conformance

extension AudioStream: CustomStringConvertible {
    /// Returns a `String` representation of self.
    public var description: String {
        return "\(name ?? "Stream \(id)") (\(id))"
    }
}

// MARK: - C Convention Functions

private func propertyListener(objectID: UInt32,
                              numInAddresses: UInt32,
                              inAddresses : UnsafePointer<AudioObjectPropertyAddress>,
                              clientData: Optional<UnsafeMutableRawPointer>) -> Int32 {
    // Try to get audio object from the pool.
    guard let obj: AudioStream = AudioObjectPool.shared.get(objectID) else { return kAudioHardwareBadObjectError }

    let address = inAddresses.pointee
    let notificationCenter = NotificationCenter.default

    switch address.mSelector {
    case kAudioStreamPropertyIsActive:
        DispatchQueue.main.async { notificationCenter.post(name: .streamIsActiveDidChange, object: obj) }
    case kAudioStreamPropertyPhysicalFormat:
        DispatchQueue.main.async { notificationCenter.post(name: .streamPhysicalFormatDidChange, object: obj) }
    default:
        break
    }

    return kAudioHardwareNoError
}
