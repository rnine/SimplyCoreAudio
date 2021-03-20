//
//  Helpers.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import XCTest
@testable import SimplyCoreAudio

func GetDevice(file: StaticString = #file, line: UInt = #line) throws -> AudioDevice {
    return try XCTUnwrap(AudioDevice.lookup(by: "NullAudioDevice_UID"), "NullAudio driver is missing.", file: file, line: line)
}
