//
//  SimplyCoreAudioTests.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import XCTest
@testable import SimplyCoreAudio

class SimplyCoreAudioTests: XCTestCase {
    let simplyCoreAudio = SimplyCoreAudio()

    func testDeviceEnumeration() throws {
        let device = try GetDevice()

        XCTAssertTrue(simplyCoreAudio.allDevices.contains(device))
        XCTAssertTrue(simplyCoreAudio.allDeviceIDs.contains(device.id))
        XCTAssertTrue(simplyCoreAudio.allInputDevices.contains(device))
        XCTAssertTrue(simplyCoreAudio.allOutputDevices.contains(device))
    }
}
