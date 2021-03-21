//
//  SimplyCoreAudioTests.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import XCTest
@testable import SimplyCoreAudio

class SimplyCoreAudioTests: SCATestCase {
    func testDeviceEnumeration() throws {
        let device = try getNullDevice()

        XCTAssertTrue(simplyCA.allDevices.contains(device))
        XCTAssertTrue(simplyCA.allDeviceIDs.contains(device.id))
        XCTAssertTrue(simplyCA.allInputDevices.contains(device))
        XCTAssertTrue(simplyCA.allOutputDevices.contains(device))
        XCTAssertTrue(simplyCA.allIODevices.contains(device))
        XCTAssertTrue(simplyCA.allNonAggregateDevices.contains(device))
        XCTAssertFalse(simplyCA.allAggregateDevices.contains(device))
    }
}
