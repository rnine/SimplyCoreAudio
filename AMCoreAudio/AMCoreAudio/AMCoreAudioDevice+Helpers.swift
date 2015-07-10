//
//  AMCoreAudioDevice+Helpers.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 10/07/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import Foundation
import CoreAudio.AudioHardwareBase

extension AMCoreAudioDevice {

    // MARK: - Class Methods

    internal class func getPropertyDataSize<Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout andSize size: UInt32) -> (OSStatus) {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(deviceID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }

    internal class func getPropertyDataSize<Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout andSize size: UInt32) -> (OSStatus) {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(deviceID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }

    internal class func getPropertyDataSize(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andSize size: UInt32) -> (OSStatus) {
        var nilValue: NilLiteralConvertible?
        return getPropertyDataSize(deviceID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, andSize: &size)
    }

    internal class func getPropertyData<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        var theAddress = address
        var size = UInt32(sizeof(T))
        let status = AudioObjectGetPropertyData(deviceID, &theAddress, UInt32(0), nil, &size, &value)

        return status
    }

    internal class func getPropertyDataArray<T,Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        var size = UInt32(0)
        let sizeStatus = getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)

        if noErr == sizeStatus {
            value = [T](count: Int(size) / sizeof(T), repeatedValue: defaultValue)
        } else {
            return sizeStatus
        }

        var theAddress = address
        let status = AudioObjectGetPropertyData(deviceID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size, &value)

        return status
    }

    internal class func getPropertyDataArray<T,Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        var size = UInt32(0)
        let sizeStatus = getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)

        if noErr == sizeStatus {
            value = [T](count: Int(size) / sizeof(T), repeatedValue: defaultValue)
        } else {
            return sizeStatus
        }

        var theAddress = address
        let status = AudioObjectGetPropertyData(deviceID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size, &value)

        return status
    }

    internal class func getPropertyDataArray<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        var nilValue: NilLiteralConvertible?
        return getPropertyDataArray(deviceID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, value: &value, andDefaultValue: defaultValue)
    }

    // MARK: - Instance Methods

    internal func getPropertyDataSize<Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize<Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andSize size: UInt32) -> OSStatus {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, andSize: &size)
    }

    internal func getPropertyDataSize<Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize<Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout andSize size: UInt32) -> (OSStatus) {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, andSize: &size)
    }

    internal func getPropertyDataSize(address: AudioObjectPropertyAddress, inout andSize size: UInt32) -> OSStatus {
        return self.dynamicType.getPropertyDataSize(deviceID, address: address, andSize: &size)
    }

    internal func getPropertyData<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        return self.dynamicType.getPropertyData(deviceID, address: address, andValue: &value)
    }

    internal func getPropertyDataArray<T,Q>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyDataArray<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return getPropertyDataArray(deviceID, address: address, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyData<T>(address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        return self.dynamicType.getPropertyData(deviceID, address: address, andValue: &value)
    }

    internal func getPropertyDataArray<T,Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: Q, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyDataArray<T,Q>(address: AudioObjectPropertyAddress, qualifierDataSize: UInt32?, inout qualifierData: [Q], inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(deviceID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData, value: &value, andDefaultValue: defaultValue)
    }

    internal func getPropertyDataArray<T>(address: AudioObjectPropertyAddress, inout value: [T], andDefaultValue defaultValue: T) -> OSStatus {
        return self.dynamicType.getPropertyDataArray(deviceID, address: address, value: &value, andDefaultValue: defaultValue)
    }

    internal func setPropertyData<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        var theAddress = address
        let size = UInt32(sizeof(T))
        let status = AudioObjectSetPropertyData(deviceID, &theAddress, UInt32(0), nil, size, &value)

        return status
    }

    internal func setPropertyData<T>(deviceID: AudioDeviceID, address: AudioObjectPropertyAddress, inout andValue value: [T]) -> OSStatus {
        var theAddress = address
        let size = UInt32(value.count * sizeof(T))
        let status = AudioObjectSetPropertyData(deviceID, &theAddress, UInt32(0), nil, size, &value)

        return status
    }

    internal func setPropertyData<T>(address: AudioObjectPropertyAddress, inout andValue value: T) -> OSStatus {
        return setPropertyData(deviceID, address: address, andValue: &value)
    }

    internal func setPropertyData<T>(address: AudioObjectPropertyAddress, inout andValue value: [T]) -> OSStatus {
        return setPropertyData(deviceID, address: address, andValue: &value)
    }
}