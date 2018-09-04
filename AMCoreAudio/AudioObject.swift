//
//  AudioObject.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Foundation
import CoreAudio.AudioHardwareBase


internal class AudioObjectPool: NSObject {

    static var instancePool: NSMapTable<NSNumber, AudioObject> = NSMapTable.weakToWeakObjects()
}


/**
    This class represents a Core Audio object currently present in the system. In Core Audio,
    audio objects are referenced by its `AudioObjectID` and belong to a specific `AudioClassID`. 
    For more information, please refer to Core Audio's documentation or source code.
 */
public class AudioObject {

    internal var objectID: AudioObjectID

    internal init(objectID: AudioObjectID) {

        self.objectID = objectID
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

        - Returns: *(optional)* An `AudioObject`.
     */
    public lazy var owningObject: AudioObject? = {

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

        return AudioObject(objectID: objectID)
    }()

    /**
        The audio device that owns this audio object.

        - Returns: *(optional)* An `AudioDevice`.
     */
    public lazy var owningDevice: AudioDevice? = {

        guard let object = self.owningObject, object.classID == kAudioDeviceClassID else { return nil }

        return AudioDevice.lookup(by: object.objectID)
    }()

    /**
        The audio object's name as reported by the system.

        - Returns: *(optional)* An audio object's name.
     */
    internal var name: String? {

        var name: CFString = "" as CFString

        let address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        let status = getPropertyData(address, andValue: &name)

        return noErr == status ? (name as String) : nil
    }
}

extension AudioObject {


    // MARK: - Class Functions

    internal class func address(selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMaster) -> AudioObjectPropertyAddress {

        return AudioObjectPropertyAddress(mSelector: selector,
                                          mScope: scope,
                                          mElement: element)
    }

    internal class func getPropertyDataSize<Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout [Q], andSize size: inout UInt32) -> (OSStatus) {

        var theAddress = address

        return AudioObjectGetPropertyDataSize(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }

    internal class func getPropertyDataSize<Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, andSize size: inout UInt32) -> (OSStatus) {

        var theAddress = address

        return AudioObjectGetPropertyDataSize(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }

    internal class func getPropertyDataSize(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andSize size: inout UInt32) -> (OSStatus) {

        var nilValue: ExpressibleByNilLiteral?

        return getPropertyDataSize(objectID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, andSize: &size)
    }

    internal class func getPropertyData<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {

        var theAddress = address
        var size = UInt32(MemoryLayout<T>.size)
        let status = AudioObjectGetPropertyData(objectID, &theAddress, UInt32(0), nil, &size, &value)

        return status
    }

    internal class func getPropertyDataArray<T,Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {

        var size = UInt32(0)
        let sizeStatus = getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)

        if noErr == sizeStatus {
            value = [T](repeating: defaultValue, count: Int(size) / MemoryLayout<T>.size)
        } else {
            return sizeStatus
        }

        var theAddress = address
        let status = AudioObjectGetPropertyData(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size, &value)

        return status
    }

    internal class func getPropertyDataArray<T,Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout [Q], value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {

        var size = UInt32(0)
        let sizeStatus = getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)

        if noErr == sizeStatus {
            value = [T](repeating: defaultValue, count: Int(size) / MemoryLayout<T>.size)
        } else {
            return sizeStatus
        }

        var theAddress = address
        let status = AudioObjectGetPropertyData(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size, &value)

        return status
    }

    internal class func getPropertyDataArray<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {

        var nilValue: ExpressibleByNilLiteral?

        return getPropertyDataArray(objectID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, value: &value, andDefaultValue: defaultValue)
    }


    // MARK: - Instance Functions

    internal func getPropertyDataSize<Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout [Q], andSize size: inout UInt32) -> (OSStatus) {

        return type(of: self).getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize<Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, andSize size: inout UInt32) -> (OSStatus) {

        return type(of: self).getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andSize size: inout UInt32) -> OSStatus {

        return type(of: self).getPropertyDataSize(objectID, address: address, andSize: &size)
    }

    internal func getPropertyDataSize<Q>(_ address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout [Q], andSize size: inout UInt32) -> (OSStatus) {

        return type(of: self).getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize<Q>(_ address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, andSize size: inout UInt32) -> (OSStatus) {

        return type(of: self).getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize(_ address: AudioObjectPropertyAddress, andSize size: inout UInt32) -> OSStatus {

        return type(of: self).getPropertyDataSize(objectID, address: address, andSize: &size)
    }

    internal func getPropertyData<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {

        return type(of: self).getPropertyData(objectID, address: address, andValue: &value)
    }

    internal func getPropertyDataArray<T,Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {

        return type(of: self).getPropertyDataArray(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyData<T>(_ address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {

        return type(of: self).getPropertyData(objectID, address: address, andValue: &value)
    }

    internal func getPropertyDataArray<T,Q>(_ address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {

        return type(of: self).getPropertyDataArray(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyDataArray<T,Q>(_ address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout [Q], value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {

        return type(of: self).getPropertyDataArray(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyDataArray<T>(_ address: AudioObjectPropertyAddress, value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {

        return type(of: self).getPropertyDataArray(objectID, address: address, value: &value, andDefaultValue: defaultValue)
    }

    internal func setPropertyData<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {

        var theAddress = address
        let size = UInt32(MemoryLayout<T>.size)
        let status = AudioObjectSetPropertyData(objectID, &theAddress, UInt32(0), nil, size, &value)

        return status
    }

    internal func setPropertyData<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andValue value: inout [T]) -> OSStatus {

        var theAddress = address
        let size = UInt32(value.count * MemoryLayout<T>.size)
        let status = AudioObjectSetPropertyData(objectID, &theAddress, UInt32(0), nil, size, &value)

        return status
    }

    internal func setPropertyData<T>(_ address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {

        return setPropertyData(objectID, address: address, andValue: &value)
    }

    internal func setPropertyData<T>(_ address: AudioObjectPropertyAddress, andValue value: inout [T]) -> OSStatus {

        return setPropertyData(objectID, address: address, andValue: &value)
    }

    internal func address(selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMaster) -> AudioObjectPropertyAddress {

        return AudioObject.address(selector: selector, scope: scope, element: element)
    }

    internal func validAddress(selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMaster) -> AudioObjectPropertyAddress? {

        var address = self.address(selector: selector, scope: scope, element: element)

        if AudioObjectHasProperty(self.objectID, &address) {
            return address
        } else {
            return nil
        }
    }

    // getProperty with default value
    internal func getProperty<T>(address: AudioObjectPropertyAddress, defaultValue: T) -> T? {

        var value = defaultValue
        let status = getPropertyData(address, andValue: &value)

        switch status {
        case noErr:

            return value

        default:

            log("Unable to get property with address (\(address)). Status: \(status)")
            return nil
        }
    }

    internal func getProperty(address: AudioObjectPropertyAddress, defaultValue: CFString) -> String? {

        var value = defaultValue
        let status = getPropertyData(address, andValue: &value)

        switch status {
        case noErr:

            return value as String

        default:

            log("Unable to get property with address (\(address)). Status: \(status)")
            return nil

        }
    }

    // getProperty UInt32
    internal func getProperty(address: AudioObjectPropertyAddress) -> UInt32? {

        return getProperty(address: address, defaultValue: UInt32(0))
    }

    // getProperty Float32
    internal func getProperty(address: AudioObjectPropertyAddress) -> Float32? {

        return getProperty(address: address, defaultValue: Float32(0.0))
    }

    // getProperty Float64
    internal func getProperty(address: AudioObjectPropertyAddress) -> Float64? {

        return getProperty(address: address, defaultValue: Float64(0.0))
    }

    // getProperty Bool
    internal func getProperty(address: AudioObjectPropertyAddress) -> Bool? {

        if let value = getProperty(address: address, defaultValue: UInt32(0)) {
            return value != 0
        } else {
            return nil
        }
    }

    // getProperty String
    internal func getProperty(address: AudioObjectPropertyAddress) -> String? {

        return getProperty(address: address, defaultValue: "" as CFString)
    }

    // setProperty T
    internal func setProperty<T>(address: AudioObjectPropertyAddress, value: T) -> Bool {

        let status: OSStatus

        if let unwrappedValue = value as? Bool {
            var newValue: UInt32 = unwrappedValue == true ? 1 : 0
            status = setPropertyData(address, andValue: &newValue)
        } else if let unwrappedValue = value as? String {
            var newValue: CFString = unwrappedValue as CFString
            status = setPropertyData(address, andValue: &newValue)
        } else {
            var newValue = value
            status = setPropertyData(address, andValue: &newValue)
        }

        switch status {
        case noErr:

            return true

        default:

            log("Unable to set property with address (\(address)). Status: \(status)")
            return false

        }
    }
}


extension AudioObject: Hashable {

    /**
        The hash value.
     */
    public var hashValue: Int {

        return Int(objectID)
    }
}

/// :nodoc:
public func ==(lhs: AudioObject, rhs: AudioObject) -> Bool {

    return lhs.hashValue == rhs.hashValue
}
