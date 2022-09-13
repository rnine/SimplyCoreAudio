//
//  AudioObject+Helpers.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import CoreAudio
import Foundation
import os.log

// MARK: - Class Functions

extension AudioObject {
    class func address(selector: AudioObjectPropertySelector,
                       scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                       element: AudioObjectPropertyElement = Element.main.asPropertyElement) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
    }

    class func getPropertyDataSize<Q>(_ objectID: AudioObjectID,
                                      address: AudioObjectPropertyAddress,
                                      qualifierDataSize: UInt32?,
                                      qualifierData: inout [Q],
                                      andSize size: inout UInt32) -> (OSStatus) {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(objectID,
                                              &theAddress,
                                              qualifierDataSize ?? UInt32(0),
                                              &qualifierData,
                                              &size)
    }

    class func getPropertyDataSize<Q>(_ objectID: AudioObjectID,
                                      address: AudioObjectPropertyAddress,
                                      qualifierDataSize: UInt32?,
                                      qualifierData: inout Q,
                                      andSize size: inout UInt32) -> (OSStatus) {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(objectID,
                                              &theAddress,
                                              qualifierDataSize ?? UInt32(0),
                                              &qualifierData,
                                              &size)
    }

    class func getPropertyDataSize(_ objectID: AudioObjectID,
                                   address: AudioObjectPropertyAddress,
                                   andSize size: inout UInt32) -> (OSStatus) {
        var nilValue: ExpressibleByNilLiteral?

        return getPropertyDataSize(objectID,
                                   address: address,
                                   qualifierDataSize: nil,
                                   qualifierData: &nilValue,
                                   andSize: &size)
    }

    class func getPropertyData<T>(_ objectID: AudioObjectID,
                                  address: AudioObjectPropertyAddress,
                                  andValue value: inout T) -> OSStatus {
        var theAddress = address
        var size = UInt32(MemoryLayout<T>.size)

        return AudioObjectGetPropertyData(objectID, &theAddress, UInt32(0), nil, &size, &value)
    }

    class func getPropertyDataArray<T, Q>(_ objectID: AudioObjectID,
                                          address: AudioObjectPropertyAddress,
                                          qualifierDataSize: UInt32?,
                                          qualifierData: inout Q,
                                          value: inout [T],
                                          andDefaultValue defaultValue: T) -> OSStatus {
        var size = UInt32(0)

        let sizeStatus = getPropertyDataSize(objectID,
                                             address: address,
                                             qualifierDataSize: qualifierDataSize,
                                             qualifierData: &qualifierData,
                                             andSize: &size)

        if noErr == sizeStatus {
            value = [T](repeating: defaultValue, count: Int(size) / MemoryLayout<T>.size)
        } else {
            return sizeStatus
        }

        var theAddress = address

        return AudioObjectGetPropertyData(objectID,
                                          &theAddress,
                                          qualifierDataSize ?? UInt32(0),
                                          &qualifierData,
                                          &size,
                                          &value)
    }

    class func getPropertyDataArray<T, Q>(_ objectID: AudioObjectID,
                                          address: AudioObjectPropertyAddress,
                                          qualifierDataSize: UInt32?,
                                          qualifierData: inout [Q],
                                          value: inout [T],
                                          andDefaultValue defaultValue: T) -> OSStatus {
        var size = UInt32(0)
        let sizeStatus = getPropertyDataSize(objectID,
                                             address: address,
                                             qualifierDataSize: qualifierDataSize,
                                             qualifierData: &qualifierData,
                                             andSize: &size)

        if noErr == sizeStatus {
            value = [T](repeating: defaultValue, count: Int(size) / MemoryLayout<T>.size)
        } else {
            return sizeStatus
        }

        var theAddress = address

        return AudioObjectGetPropertyData(objectID,
                                          &theAddress,
                                          qualifierDataSize ?? UInt32(0),
                                          &qualifierData,
                                          &size,
                                          &value)
    }

    class func getPropertyDataArray<T>(_ objectID: AudioObjectID,
                                       address: AudioObjectPropertyAddress,
                                       value: inout [T],
                                       andDefaultValue defaultValue: T) -> OSStatus {
        var nilValue: ExpressibleByNilLiteral?

        return getPropertyDataArray(objectID,
                                    address: address,
                                    qualifierDataSize: nil,
                                    qualifierData: &nilValue,
                                    value: &value,
                                    andDefaultValue: defaultValue)
    }
}

// MARK: - Instance Functions

extension AudioObject {
    func getPropertyDataSize<Q>(_ objectID: AudioObjectID,
                                address: AudioObjectPropertyAddress,
                                qualifierDataSize: UInt32?,
                                qualifierData: inout [Q],
                                andSize size: inout UInt32) -> (OSStatus) {
        type(of: self).getPropertyDataSize(objectID,
                                           address: address,
                                           qualifierDataSize: qualifierDataSize,
                                           qualifierData: &qualifierData,
                                           andSize: &size)
    }

    func getPropertyDataSize<Q>(_ objectID: AudioObjectID,
                                address: AudioObjectPropertyAddress,
                                qualifierDataSize: UInt32?,
                                qualifierData: inout Q,
                                andSize size: inout UInt32) -> (OSStatus) {
        type(of: self).getPropertyDataSize(objectID,
                                           address: address,
                                           qualifierDataSize: qualifierDataSize,
                                           qualifierData: &qualifierData,
                                           andSize: &size)
    }

    func getPropertyDataSize(_ objectID: AudioObjectID,
                             address: AudioObjectPropertyAddress,
                             andSize size: inout UInt32) -> OSStatus {
        type(of: self).getPropertyDataSize(objectID, address: address, andSize: &size)
    }

    func getPropertyDataSize<Q>(_ address: AudioObjectPropertyAddress,
                                qualifierDataSize: UInt32?,
                                qualifierData: inout [Q],
                                andSize size: inout UInt32) -> (OSStatus) {
        type(of: self).getPropertyDataSize(objectID,
                                           address: address,
                                           qualifierDataSize: qualifierDataSize,
                                           qualifierData: &qualifierData,
                                           andSize: &size)
    }

    func getPropertyDataSize<Q>(_ address: AudioObjectPropertyAddress,
                                qualifierDataSize: UInt32?,
                                qualifierData: inout Q,
                                andSize size: inout UInt32) -> (OSStatus) {
        type(of: self).getPropertyDataSize(objectID,
                                           address: address,
                                           qualifierDataSize: qualifierDataSize,
                                           qualifierData: &qualifierData,
                                           andSize: &size)
    }

    func getPropertyDataSize(_ address: AudioObjectPropertyAddress, andSize size: inout UInt32) -> OSStatus {
        type(of: self).getPropertyDataSize(objectID, address: address, andSize: &size)
    }

    func getPropertyData<T>(_ objectID: AudioObjectID,
                            address: AudioObjectPropertyAddress,
                            andValue value: inout T) -> OSStatus {
        type(of: self).getPropertyData(objectID, address: address, andValue: &value)
    }

    func getPropertyDataArray<T, Q>(_ objectID: AudioObjectID,
                                    address: AudioObjectPropertyAddress,
                                    qualifierDataSize: UInt32?,
                                    qualifierData: inout Q,
                                    value: inout [T],
                                    andDefaultValue defaultValue: T) -> OSStatus {
        type(of: self).getPropertyDataArray(objectID,
                                            address: address,
                                            qualifierDataSize: qualifierDataSize,
                                            qualifierData: &qualifierData,
                                            value: &value,
                                            andDefaultValue: defaultValue)
    }

    func getPropertyData<T>(_ address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {
        type(of: self).getPropertyData(objectID, address: address, andValue: &value)
    }

    func getPropertyDataArray<T, Q>(_ address: AudioObjectPropertyAddress,
                                    qualifierDataSize: UInt32?,
                                    qualifierData: inout Q,
                                    value: inout [T],
                                    andDefaultValue defaultValue: T) -> OSStatus {
        type(of: self).getPropertyDataArray(objectID,
                                            address: address,
                                            qualifierDataSize: qualifierDataSize,
                                            qualifierData: &qualifierData,
                                            value: &value,
                                            andDefaultValue: defaultValue)
    }

    func getPropertyDataArray<T, Q>(_ address: AudioObjectPropertyAddress,
                                    qualifierDataSize: UInt32?,
                                    qualifierData: inout [Q],
                                    value: inout [T],
                                    andDefaultValue defaultValue: T) -> OSStatus {
        type(of: self).getPropertyDataArray(objectID,
                                            address: address,
                                            qualifierDataSize: qualifierDataSize,
                                            qualifierData: &qualifierData,
                                            value: &value,
                                            andDefaultValue: defaultValue)
    }

    func getPropertyDataArray<T>(_ address: AudioObjectPropertyAddress,
                                 value: inout [T],
                                 andDefaultValue defaultValue: T) -> OSStatus {
        type(of: self).getPropertyDataArray(objectID,
                                            address: address,
                                            value: &value,
                                            andDefaultValue: defaultValue)
    }

    func setPropertyData<T>(_ objectID: AudioObjectID,
                            address: AudioObjectPropertyAddress,
                            andValue value: inout T) -> OSStatus {
        var theAddress = address
        let size = UInt32(MemoryLayout<T>.size)

        return AudioObjectSetPropertyData(objectID, &theAddress, UInt32(0), nil, size, &value)
    }

    func setPropertyData<T>(_ objectID: AudioObjectID,
                            address: AudioObjectPropertyAddress,
                            andValue value: inout [T]) -> OSStatus {
        var theAddress = address
        let size = UInt32(value.count * MemoryLayout<T>.size)

        return AudioObjectSetPropertyData(objectID, &theAddress, UInt32(0), nil, size, &value)
    }

    func setPropertyData<T>(_ address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {
        setPropertyData(objectID, address: address, andValue: &value)
    }

    func setPropertyData<T>(_ address: AudioObjectPropertyAddress, andValue value: inout [T]) -> OSStatus {
        setPropertyData(objectID, address: address, andValue: &value)
    }

    func address(selector: AudioObjectPropertySelector,
                 scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                 element: AudioObjectPropertyElement = Element.main.asPropertyElement) -> AudioObjectPropertyAddress {
        AudioObject.address(selector: selector, scope: scope, element: element)
    }

    func validAddress(selector: AudioObjectPropertySelector,
                      scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                      element: AudioObjectPropertyElement = Element.main.asPropertyElement)-> AudioObjectPropertyAddress? {
        var address = self.address(selector: selector, scope: scope, element: element)

        guard AudioObjectHasProperty(objectID, &address) else { return nil }

        return address
    }

    // getProperty<T> with default value
    func getProperty<T>(address: AudioObjectPropertyAddress, defaultValue: T) -> T? {
        var value = defaultValue
        let status = getPropertyData(address, andValue: &value)

        switch status {
        case noErr:
            return value
        default:
            os_log("Unable to get property with address (%@). Status: %@",
                   log: .default,
                   type: .debug,
                   String(describing: address), status)
            return nil
        }
    }

    // getProperty UInt32
    func getProperty(address: AudioObjectPropertyAddress) -> UInt32? {
        getProperty(address: address, defaultValue: UInt32(0))
    }

    // getProperty Float32
    func getProperty(address: AudioObjectPropertyAddress) -> Float32? {
        getProperty(address: address, defaultValue: Float32(0.0))
    }

    // getProperty Float64
    func getProperty(address: AudioObjectPropertyAddress) -> Float64? {
        getProperty(address: address, defaultValue: Float64(0.0))
    }

    // getProperty String
    func getProperty(address: AudioObjectPropertyAddress) -> String? {
        getProperty(address: address, defaultValue: "" as CFString) as String?
    }

    // getProperty Bool
    func getProperty(address: AudioObjectPropertyAddress) -> Bool? {
        guard let value = getProperty(address: address, defaultValue: UInt32(0)) else { return nil }
        return Bool(value)
    }

    // setProperty<T>
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
            return false
        }
    }
}
