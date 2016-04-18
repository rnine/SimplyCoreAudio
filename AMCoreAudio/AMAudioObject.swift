//
//  AMAudioObject.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Foundation
import CoreAudio.AudioHardwareBase

public class AMAudioObjectPool: NSObject {
    public static var instancePool = NSMapTable(keyOptions: .WeakMemory, valueOptions: .WeakMemory)
}

public class AMAudioObject: NSObject {
    internal var objectID: AudioObjectID

    internal func directionToScope(direction: Direction) -> AudioObjectPropertyScope {
        return AMUtils.directionToScope(direction)
    }

    internal func scopeToDirection(scope: AudioObjectPropertyScope) -> Direction {
        return AMUtils.scopeToDirection(scope)
    }

    internal init(objectID: AudioObjectID) {
        self.objectID = objectID
        super.init()
    }

    deinit {
        // NO-OP
    }

    /**
        The `AudioClassID` that identifies the class of this audio object.

        - Returns: *(optional)* An `AudioClassID`.
     */
    public lazy var classID: AudioClassID? = {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyClass,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        if !AudioObjectHasProperty(self.objectID, &address) {
            return nil
        }

        var klassID = AudioClassID()
        let status = self.getPropertyData(address, andValue: &klassID)

        if noErr != status {
            return nil
        }

        return klassID
    }()

    /**
        The audio object that owns this audio object.

        - Returns: *(optional)* An `AMAudioObject`.
     */
    public lazy var owningObject: AMAudioObject? = {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyOwner,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        if !AudioObjectHasProperty(self.objectID, &address) {
            return nil
        }

        var objectID = AudioObjectID()
        let status = self.getPropertyData(address, andValue: &objectID)

        if noErr != status {
            return nil
        }

        return AMAudioObject(objectID: objectID)
    }()

    /**
        The audio device that owns this audio object.

        - Returns: *(optional)* An `AMAudioDevice`.
     */
    public lazy var owningDevice: AMAudioDevice? = {
        if let object = self.owningObject {
            if object.classID == kAudioDeviceClassID {
                return AMAudioDevice.lookupByID(object.objectID)
            }
        }

        return nil
    }()
}

extension AMAudioObject {

    // MARK: - Class Functions

    internal class func getPropertyDataSize<Q>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout andSize size: UInt32) -> (OSStatus) {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }

    internal class func getPropertyDataSize<Q>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout andSize size: UInt32) -> (OSStatus) {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }

    internal class func getPropertyDataSize(objectID: AudioObjectID, address: AudioObjectPropertyAddress, inout andSize size: UInt32) -> (OSStatus) {
        var nilValue: NilLiteralConvertible?
        return getPropertyDataSize(objectID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, andSize: &size)
    }

    internal class func getPropertyData<T>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        var theAddress = address
        var size = UInt32(sizeof(T))
        let status = AudioObjectGetPropertyData(objectID, &theAddress, UInt32(0), nil, &size, &value)

        return status
    }

    internal class func getPropertyDataArray<T,Q>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        var size = UInt32(0)
        let sizeStatus = getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)

        if noErr == sizeStatus {
            value = [T](count: Int(size) / sizeof(T), repeatedValue: defaultValue)
        } else {
            return sizeStatus
        }

        var theAddress = address
        let status = AudioObjectGetPropertyData(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size, &value)

        return status
    }

    internal class func getPropertyDataArray<T,Q>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        var size = UInt32(0)
        let sizeStatus = getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)

        if noErr == sizeStatus {
            value = [T](count: Int(size) / sizeof(T), repeatedValue: defaultValue)
        } else {
            return sizeStatus
        }

        var theAddress = address
        let status = AudioObjectGetPropertyData(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size, &value)

        return status
    }

    internal class func getPropertyDataArray<T>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        var nilValue: NilLiteralConvertible?
        return getPropertyDataArray(objectID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, value: &value, andDefaultValue: defaultValue)
    }

    // MARK: - Instance Functions

    internal func getPropertyDataSize<Q>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize<Q>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize(objectID: AudioObjectID, address: AudioObjectPropertyAddress, inout andSize size: UInt32) -> OSStatus {
        return self.dynamicType.getPropertyDataSize(objectID, address: address, andSize: &size)
    }

    internal func getPropertyDataSize<Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize<Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize(address: AudioObjectPropertyAddress, inout andSize size: UInt32) -> OSStatus {
        return self.dynamicType.getPropertyDataSize(objectID, address: address, andSize: &size)
    }

    internal func getPropertyData<T>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        return self.dynamicType.getPropertyData(objectID, address: address, andValue: &value)
    }

    internal func getPropertyDataArray<T,Q>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyDataArray<T>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return getPropertyDataArray(objectID, address: address, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyData<T>(address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        return self.dynamicType.getPropertyData(objectID, address: address, andValue: &value)
    }

    internal func getPropertyDataArray<T,Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyDataArray<T,Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyDataArray<T>(address: AudioObjectPropertyAddress, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(objectID, address: address, value: &value, andDefaultValue: defaultValue)
    }

    internal func setPropertyData<T>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        var theAddress = address
        let size = UInt32(sizeof(T))
        let status = AudioObjectSetPropertyData(objectID, &theAddress, UInt32(0), nil, size, &value)

        return status
    }

    internal func setPropertyData<T>(objectID: AudioObjectID, address: AudioObjectPropertyAddress, inout andValue value: [T]) -> OSStatus {
        var theAddress = address
        let size = UInt32(value.count * sizeof(T))
        let status = AudioObjectSetPropertyData(objectID, &theAddress, UInt32(0), nil, size, &value)

        return status
    }

    internal func setPropertyData<T>(address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        return setPropertyData(objectID, address: address, andValue: &value)
    }

    internal func setPropertyData<T>(address: AudioObjectPropertyAddress, inout andValue value: [T]) -> OSStatus {
        return setPropertyData(objectID, address: address, andValue: &value)
    }
}
