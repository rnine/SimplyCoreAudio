//
//  SimplyCoreAudioTests.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import os.log
@testable import SimplyCoreAudio
import XCTest

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

    func testLogs() {
        OSLog.error("⚠️", "☢️", "🛑", nil)
        OSLog.debug("🐞", "🐛", "🐜", nil)
    }

    func testInvalidProperties() throws {
        let device = try getNullDevice()

        let address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(0),
            mScope: AudioObjectPropertyScope(0),
            mElement: AudioObjectPropertyScope(0)
        )

        // Just testing these fail gracefully and spit out a friendly error message

        let result1: UInt32? = device.getProperty(address: address)
        XCTAssertNil(result1)

        let result2: Float32? = device.getProperty(address: address)
        XCTAssertNil(result2)

        let result3: Float64? = device.getProperty(address: address)
        XCTAssertNil(result3)

        let result4: String? = device.getProperty(address: address)
        XCTAssertNil(result4)

        let result5: Bool? = device.getProperty(address: address)
        XCTAssertNil(result5)
    }
}
