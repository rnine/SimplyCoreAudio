//
//  AMCoreAudioStream.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Foundation

/// `AMCoreAudioStreamDelegate` protocol
public protocol AMCoreAudioStreamDelegate: class {
    /**
        Called whenever the audio stream `isActive` flag changes state.
     */
    func audioStreamIsActiveChanged(audioStream: AMCoreAudioStream)

    /**
        Called whenever the audio stream physical format changes.
     */
    func audioStreamPhysicalFormatChanged(audioStream: AMCoreAudioStream)
}

/// Optional `AMCoreAudioStreamDelegate` protocol methods
public extension AMCoreAudioStreamDelegate {
    func audioStreamIsActiveChanged(audioStream: AMCoreAudioStream) {}
    func audioStreamPhysicalFormatChanged(audioStream: AMCoreAudioStream) {}
}

/**
    `AMCoreAudioStream`
 */
final public class AMCoreAudioStream: AMCoreAudioObject {

    /**
        A delegate conforming to the `AMCoreAudioStreamDelegate` protocol.
     */
    public weak var delegate: AMCoreAudioStreamDelegate? {
        didSet {
            if delegate != nil {
                registerForNotifications()
            } else {
                unregisterForNotifications()
            }
        }
    }

    /**
        The audio stream ID that this `AMCoreAudioStream` instance represents.

        - Returns: An `AudioObjectID`
     */
    public var streamID: AudioObjectID {
        get {
            return objectID
        }
    }

    /**
        Returns whether this audio stream stream is enabled and doing IO.
     
        - Returns: `true` when enabled, `false` otherwise
     */
    public lazy var active: Bool = {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyIsActive,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        if !AudioObjectHasProperty(self.streamID, &address) {
            return false
        }

        var active: UInt32 = 0
        let status = self.getPropertyData(address, andValue: &active)

        if noErr != status {
            return false
        }

        return active == 1
    }()

    /**
        Returns a `UInt32` that specifies the first element in the owning device that corresponds to
        element one of this stream.

        - Returns: *(optional)* A `UInt32`
     */
    public lazy var startingChannel: UInt32? = {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyStartingChannel,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        if !AudioObjectHasProperty(self.streamID, &address) {
            return nil
        }

        var startingChannel: UInt32 = 0
        let status = self.getPropertyData(address, andValue: &startingChannel)

        if noErr != status {
            return nil
        }

        return startingChannel
    }()

    /**
        Audio stream direction. 
        
        For output streams, and to continue using the same `Direction` concept used by `AMCoreAudioDevice`,
        this will be `Direction.Playback`, likewise, for input streams, `Direction.Recording` will be returned.

        - Returns: *(optional)* A `Direction`
     */
    public lazy var direction: Direction? = {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyDirection,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        if !AudioObjectHasProperty(self.streamID, &address) {
            return nil
        }

        var direction: UInt32 = 0
        let status = self.getPropertyData(address, andValue: &direction)

        if noErr != status {
            return nil
        }

        switch direction {
        case 0:
            return .Playback
        case 1:
            return .Recording
        default:
            return nil
        }
    }()

    /**
        An `AudioStreamBasicDescription` that describes the current data format for this audio stream.

        - Returns: *(optional)* An `AudioStreamBasicDescription`
     */
    public var physicalFormat: AudioStreamBasicDescription? {
        get {
            guard let direction = direction else {
                return nil
            }

            var address = AudioObjectPropertyAddress(
                mSelector: kAudioStreamPropertyPhysicalFormat,
                mScope: directionToScope(direction),
                mElement: kAudioObjectPropertyElementMaster
            )

            if !AudioObjectHasProperty(streamID, &address) {
                return nil
            }

            var asbd = AudioStreamBasicDescription()
            let status = getPropertyData(address, andValue: &asbd)

            if noErr != status {
                return nil
            }
            
            return asbd
        }

        set {
            guard let direction = direction else {
                return
            }

            var address = AudioObjectPropertyAddress(
                mSelector: kAudioStreamPropertyPhysicalFormat,
                mScope: directionToScope(direction),
                mElement: kAudioObjectPropertyElementMaster
            )

            if !AudioObjectHasProperty(streamID, &address) {
                return
            }

            var asbd = newValue
            let status = setPropertyData(address, andValue: &asbd)

            if noErr != status {
                return
            }
        }
    }


    /**
        An `AudioStreamBasicDescription` that describes the current virtual data format for this audio stream.

        - Returns: *(optional)* An `AudioStreamBasicDescription`
     */
    public var virtualFormat: AudioStreamBasicDescription? {
        get {
            guard let direction = direction else {
                return nil
            }

            var address = AudioObjectPropertyAddress(
                mSelector: kAudioStreamPropertyVirtualFormat,
                mScope: directionToScope(direction),
                mElement: kAudioObjectPropertyElementMaster
            )

            if !AudioObjectHasProperty(streamID, &address) {
                return nil
            }

            var asbd = AudioStreamBasicDescription()
            let status = getPropertyData(address, andValue: &asbd)

            if noErr != status {
                return nil
            }

            return asbd
        }

        set {
            guard let direction = direction else {
                return
            }

            var address = AudioObjectPropertyAddress(
                mSelector: kAudioStreamPropertyVirtualFormat,
                mScope: directionToScope(direction),
                mElement: kAudioObjectPropertyElementMaster
            )

            if !AudioObjectHasProperty(streamID, &address) {
                return
            }

            var asbd = newValue
            let status = setPropertyData(address, andValue: &asbd)
            
            if noErr != status {
                return
            }
        }
    }

    /**
        An array of all the available physical formats for this audio stream.

        - Returns: *(optional)* An array of `AudioStreamRangedDescription`
     */
    public lazy var availablePhysicalFormats: [AudioStreamRangedDescription]? = {
        guard let direction = self.direction else {
            return nil
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyAvailablePhysicalFormats,
            mScope: self.directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        if !AudioObjectHasProperty(self.streamID, &address) {
            return nil
        }

        var asrd = [AudioStreamRangedDescription]()
        let status = self.getPropertyDataArray(address, value: &asrd, andDefaultValue: AudioStreamRangedDescription())

        if noErr != status {
            return nil
        }

        return asrd
    }()

    /**
        An array of all the available virtual formats for this audio stream.

        - Returns: *(optional)* An array of `AudioStreamRangedDescription`
     */
    public lazy var availableVirtualFormats: [AudioStreamRangedDescription]? = {
        guard let direction = self.direction else {
            return nil
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyAvailableVirtualFormats,
            mScope: self.directionToScope(direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        if !AudioObjectHasProperty(self.streamID, &address) {
            return nil
        }

        var asrd = [AudioStreamRangedDescription]()
        let status = self.getPropertyDataArray(address, value: &asrd, andDefaultValue: AudioStreamRangedDescription())

        if noErr != status {
            return nil
        }
        
        return asrd
    }()

    private var isRegisteredForNotifications = false

    private lazy var notificationsQueue: dispatch_queue_t = {
        return dispatch_queue_create("io.9labs.AMCoreAudio.notifications", DISPATCH_QUEUE_CONCURRENT)
    }()

    // MARK: - Public Functions

    /**
        Initializes an `AMCoreAudioStream` by providing a valid `AudioObjectID` referencing an existing audio stream.
     */
    public init(streamID: AudioObjectID) {
        super.init(objectID: streamID)
    }

    /**
        An array of all the available physical formats for this audio stream matching the current
        physical format's sample rate.
     
        **Discussion:** By default, non-mixable streams are returned, however, these can be filtered 
        out by setting `includeNonMixable` to `false`.

        - Returns: *(optional)* An array of `AudioStreamBasicDescription`
     */
    public final func availablePhysicalFormatsMatchingCurrentNominalSampleRate(includeNonMixable: Bool = true) -> [AudioStreamBasicDescription]? {
        guard let physicalFormats = availablePhysicalFormats,
              let physicalFormat = physicalFormat else {
            return nil
        }

        var filteredFormats = physicalFormats.filter { (format) -> Bool in
            format.mSampleRateRange.mMinimum >= physicalFormat.mSampleRate &&
            format.mSampleRateRange.mMaximum <= physicalFormat.mSampleRate
        }.map({ (asrd) -> AudioStreamBasicDescription in
            asrd.mFormat
        })

        if !includeNonMixable {
            filteredFormats = filteredFormats.filter({ (asbd) -> Bool in
                asbd.mFormatFlags & kAudioFormatFlagIsNonMixable == 0
            })
        }

        return filteredFormats
    }

    /**
        An array of all the available virtual formats for this audio stream matching the current
        virtual format's sample rate.

        **Discussion:** By default, non-mixable streams are returned, however, these can be filtered
        out by setting `includeNonMixable` to `false`.

        - Returns: *(optional)* An array of `AudioStreamBasicDescription`
     */
    public final func availableVirtualFormatsMatchingCurrentNominalSampleRate(includeNonMixable: Bool = true) -> [AudioStreamBasicDescription]? {
        guard let virtualFormats = availableVirtualFormats,
            let virtualFormat = virtualFormat else {
                return nil
        }

        var filteredFormats = virtualFormats.filter { (format) -> Bool in
            format.mSampleRateRange.mMinimum >= virtualFormat.mSampleRate &&
                format.mSampleRateRange.mMaximum <= virtualFormat.mSampleRate
            }.map({ (asrd) -> AudioStreamBasicDescription in
                asrd.mFormat
            })

        if !includeNonMixable {
            filteredFormats = filteredFormats.filter({ (asbd) -> Bool in
                asbd.mFormatFlags & kAudioFormatFlagIsNonMixable == 0
            })
        }

        return filteredFormats
    }

    // MARK: - Private Methods

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

        let err = AudioObjectAddPropertyListenerBlock(streamID, &address, notificationsQueue, propertyListenerBlock)

        if noErr != err {
            print("Error on AudioObjectAddPropertyListenerBlock: \(err)")
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

            let err = AudioObjectRemovePropertyListenerBlock(streamID, &address, notificationsQueue, propertyListenerBlock)

            if noErr != err {
                print("Error on AudioObjectRemovePropertyListenerBlock: \(err)")
            }

            isRegisteredForNotifications = noErr != err
        } else {
            isRegisteredForNotifications = false
        }
    }

    private lazy var propertyListenerBlock: AudioObjectPropertyListenerBlock = { (inNumberAddresses, inAddresses) -> Void in
        let address = inAddresses.memory
        let direction = self.scopeToDirection(address.mScope)

        switch address.mSelector {
        case kAudioStreamPropertyIsActive:
            self.delegate?.audioStreamIsActiveChanged(self)
        case kAudioStreamPropertyPhysicalFormat:
            self.delegate?.audioStreamPhysicalFormatChanged(self)
        default:
            break
        }
    }
}
