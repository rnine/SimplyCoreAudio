//
//  AudioObject+Helpers.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 20/09/2019.
//  Copyright © 2019 9Labs. All rights reserved.
//

import CoreAudio.AudioHardwareBase
import Foundation

extension AudioObject {
    // MARK: - Class Functions

    class func address(selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMaster) -> AudioObjectPropertyAddress {
        return AudioObjectPropertyAddress(mSelector: selector,
                                          mScope: scope,
                                          mElement: element)
    }

    class func getPropertyDataSize<Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout [Q], andSize size: inout UInt32) -> (OSStatus) {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }

    class func getPropertyDataSize<Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, andSize size: inout UInt32) -> (OSStatus) {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }

    class func getPropertyDataSize(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andSize size: inout UInt32) -> (OSStatus) {
        var nilValue: ExpressibleByNilLiteral?

        return getPropertyDataSize(objectID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, andSize: &size)
    }

    class func getPropertyData<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {
        var theAddress = address
        var size = UInt32(MemoryLayout<T>.size)
        let status = AudioObjectGetPropertyData(objectID, &theAddress, UInt32(0), nil, &size, &value)

        return status
    }

    class func getPropertyDataArray<T, Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {
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

    class func getPropertyDataArray<T, Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout [Q], value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {
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

    class func getPropertyDataArray<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {
        var nilValue: ExpressibleByNilLiteral?

        return getPropertyDataArray(objectID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, value: &value, andDefaultValue: defaultValue)
    }

    // MARK: - Instance Functions

    func getPropertyDataSize<Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout [Q], andSize size: inout UInt32) -> (OSStatus) {
        return type(of: self).getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    func getPropertyDataSize<Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, andSize size: inout UInt32) -> (OSStatus) {
        return type(of: self).getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    func getPropertyDataSize(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andSize size: inout UInt32) -> OSStatus {
        return type(of: self).getPropertyDataSize(objectID, address: address, andSize: &size)
    }

    func getPropertyDataSize<Q>(_ address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout [Q], andSize size: inout UInt32) -> (OSStatus) {
        return type(of: self).getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    func getPropertyDataSize<Q>(_ address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, andSize size: inout UInt32) -> (OSStatus) {
        return type(of: self).getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    func getPropertyDataSize(_ address: AudioObjectPropertyAddress, andSize size: inout UInt32) -> OSStatus {
        return type(of: self).getPropertyDataSize(objectID, address: address, andSize: &size)
    }

    func getPropertyData<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {
        return type(of: self).getPropertyData(objectID, address: address, andValue: &value)
    }

    func getPropertyDataArray<T, Q>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {
        return type(of: self).getPropertyDataArray(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    func getPropertyData<T>(_ address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {
        return type(of: self).getPropertyData(objectID, address: address, andValue: &value)
    }

    func getPropertyDataArray<T, Q>(_ address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout Q, value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {
        return type(of: self).getPropertyDataArray(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    func getPropertyDataArray<T, Q>(_ address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, qualifierData: inout [Q], value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {
        return type(of: self).getPropertyDataArray(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    func getPropertyDataArray<T>(_ address: AudioObjectPropertyAddress, value: inout [T], andDefaultValue defaultValue: T) -> OSStatus {
        return type(of: self).getPropertyDataArray(objectID, address: address, value: &value, andDefaultValue: defaultValue)
    }

    func setPropertyData<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {
        var theAddress = address
        let size = UInt32(MemoryLayout<T>.size)
        let status = AudioObjectSetPropertyData(objectID, &theAddress, UInt32(0), nil, size, &value)

        return status
    }

    func setPropertyData<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andValue value: inout [T]) -> OSStatus {
        var theAddress = address
        let size = UInt32(value.count * MemoryLayout<T>.size)
        let status = AudioObjectSetPropertyData(objectID, &theAddress, UInt32(0), nil, size, &value)

        return status
    }

    func setPropertyData<T>(_ address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {
        return setPropertyData(objectID, address: address, andValue: &value)
    }

    func setPropertyData<T>(_ address: AudioObjectPropertyAddress, andValue value: inout [T]) -> OSStatus {
        return setPropertyData(objectID, address: address, andValue: &value)
    }

    func address(selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMaster) -> AudioObjectPropertyAddress {
        return AudioObject.address(selector: selector, scope: scope, element: element)
    }

    func validAddress(selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMaster) -> AudioObjectPropertyAddress? {
        var address = self.address(selector: selector, scope: scope, element: element)

        if AudioObjectHasProperty(self.objectID, &address) {
            return address
        } else {
            return nil
        }
    }

    // getProperty with default value
    func getProperty<T>(address: AudioObjectPropertyAddress, defaultValue: T) -> T? {
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

    func getProperty(address: AudioObjectPropertyAddress, defaultValue: CFString) -> String? {
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
    func getProperty(address: AudioObjectPropertyAddress) -> UInt32? {
        return getProperty(address: address, defaultValue: UInt32(0))
    }

    // getProperty Float32
    func getProperty(address: AudioObjectPropertyAddress) -> Float32? {
        return getProperty(address: address, defaultValue: Float32(0.0))
    }

    // getProperty Float64
    func getProperty(address: AudioObjectPropertyAddress) -> Float64? {
        return getProperty(address: address, defaultValue: Float64(0.0))
    }

    // getProperty Bool
    func getProperty(address: AudioObjectPropertyAddress) -> Bool? {
        if let value = getProperty(address: address, defaultValue: UInt32(0)) {
            return value != 0
        } else {
            return nil
        }
    }

    // getProperty String
    func getProperty(address: AudioObjectPropertyAddress) -> String? {
        return getProperty(address: address, defaultValue: "" as CFString)
    }

    // setProperty T
    func setProperty<T>(address: AudioObjectPropertyAddress, value: T) -> Bool {
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
