//
//  NotificationTests.swift
//
//  Created by Ruben Nine on 21/3/21.
//

import XCTest
@testable import SimplyCoreAudio

class NotificationTests: SCATestCase {
    func testHardwareNotifications() throws {
        let nullDevice = try getNullDevice()
        var aggregateDevice: AudioDevice?

        let expectedName = "NullDeviceAggregate"
        let expectedUID = "NullDeviceAggregate_UID"

        let expectation1 = expectation(forNotification: .deviceListChanged, object: nil) { (notification) -> Bool in
            guard let addedDevices = notification.userInfo?["addedDevices"] as? [AudioDevice] else { return false }
            guard let firstAddedDevice = addedDevices.first else { return false }
            guard firstAddedDevice.uid == expectedUID else { return false }
            guard firstAddedDevice.name == expectedName else { return false }

            return true
        }

        let expectation2 = expectation(forNotification: .defaultInputDeviceChanged, object: nil)
        let expectation3 = expectation(forNotification: .defaultOutputDeviceChanged, object: nil)
        let expectation4 = expectation(forNotification: .defaultSystemOutputDeviceChanged, object: nil)

        expectation1.expectationDescription = "aggregate device should be added to device list"
        expectation2.expectationDescription = "aggregate device should become default input device"
        expectation3.expectationDescription = "aggregate device should become default output device"
        expectation4.expectationDescription = "aggregate device should become default system output device"

        aggregateDevice = simplyCA.createAggregateDevice(mainDevice: nullDevice,
                                                         secondDevice: nil,
                                                         named: expectedName,
                                                         uid: expectedUID)
        XCTAssertNotNil(aggregateDevice)

        aggregateDevice?.isDefaultInputDevice = true
        aggregateDevice?.isDefaultOutputDevice = true
        aggregateDevice?.isDefaultSystemOutputDevice = true

        waitForExpectations(timeout: 5)

        XCTAssertEqual(aggregateDevice, simplyCA.defaultInputDevice)
        XCTAssertEqual(aggregateDevice, simplyCA.defaultOutputDevice)
        XCTAssertEqual(aggregateDevice, simplyCA.defaultSystemOutputDevice)

        if let aggregateDevice = aggregateDevice {
            XCTAssertEqual(noErr, simplyCA.removeAggregateDevice(id: aggregateDevice.id))
        }

        wait(for: 2)
    }

    func testHardwareNotificationsAreNotDuplicated() throws {
        let simplyCA2 = SimplyCoreAudio()
        let simplyCA3 = SimplyCoreAudio()

        XCTAssertNotNil(simplyCA2)
        XCTAssertNotNil(simplyCA3)

        let nullDevice = try getNullDevice()
        var aggregateDevice: AudioDevice?

        let expectedName = "NullDeviceAggregate2"
        let expectedUID = "NullDeviceAggregate2_UID"

        let expectation1 = expectation(forNotification: .deviceListChanged, object: nil) { (notification) -> Bool in
            guard let addedDevices = notification.userInfo?["addedDevices"] as? [AudioDevice] else { return false }
            guard let firstAddedDevice = addedDevices.first else { return false }
            guard firstAddedDevice.uid == expectedUID else { return false }
            guard firstAddedDevice.name == expectedName else { return false }

            let expectation2 = self.expectation(forNotification: .deviceListChanged, object: nil)
            let expectation3 = self.expectation(forNotification: .deviceListChanged, object: nil)

            expectation2.expectationDescription = "deviceListChanged should not be called again (1)"
            expectation2.isInverted = true
            expectation3.expectationDescription = "deviceListChanged should not be called again (2)"
            expectation3.isInverted = true

            return true
        }

        expectation1.expectationDescription = "deviceListChanged should be called with added aggregate device"

        aggregateDevice = simplyCA.createAggregateDevice(mainDevice: nullDevice,
                                                         secondDevice: nil,
                                                         named: expectedName,
                                                         uid: expectedUID)
        XCTAssertNotNil(aggregateDevice)

        waitForExpectations(timeout: 5)

        if let aggregateDevice = aggregateDevice {
            XCTAssertEqual(noErr, simplyCA.removeAggregateDevice(id: aggregateDevice.id))
        }

        wait(for: 2)
    }

    func testDeviceSamplerateDidChangeNotification() throws {
        let nullDevice = try getNullDevice()
        let baseSamplerate = 44100.0
        let targetSamplerate = 48000.0

        XCTAssertEqual(nullDevice.nominalSampleRate, baseSamplerate)
        XCTAssertTrue(nullDevice.nominalSampleRates!.contains(targetSamplerate))

        let expectation1 = self.expectation(forNotification: .deviceNominalSampleRateDidChange, object: nullDevice)
        expectation1.expectationDescription = "device samplerate should change"

        nullDevice.setNominalSampleRate(targetSamplerate)

        waitForExpectations(timeout: 5)

        XCTAssertEqual(nullDevice.nominalSampleRate, targetSamplerate)
    }

    func testDeviceVolumeDidChangeNotification() throws {
        let nullDevice = try getNullDevice()

        let expectation1 = expectation(forNotification: .deviceVolumeDidChange, object: nullDevice) { notification -> Bool in
            guard let channel = notification.userInfo?["channel"] as? UInt32 else { return false }
            guard let scope = notification.userInfo?["scope"] as? Scope else { return false }
            guard scope == .output, channel == 0 else { return false }

            return true
        }

        expectation1.expectationDescription = "device output volumes should change"

        nullDevice.setVirtualMainVolume(1, scope: .output)

        waitForExpectations(timeout: 5)

        let expectation2 = expectation(forNotification: .deviceVolumeDidChange, object: nullDevice) { notification -> Bool in
            guard let channel = notification.userInfo?["channel"] as? UInt32 else { return false }
            guard let scope = notification.userInfo?["scope"] as? Scope else { return false }
            guard scope == .input, channel == 0 else { return false }

            return true
        }

        expectation2.expectationDescription = "device input volumes should change"

        nullDevice.setVirtualMainVolume(1, scope: .input)

        waitForExpectations(timeout: 5)

        XCTAssertEqual(nullDevice.virtualMainVolume(scope: .output), 1)
        XCTAssertEqual(nullDevice.virtualMainVolume(scope: .input), 1)
    }

    func testDeviceMuteDidChangeNotification() throws {
        let nullDevice = try getNullDevice()

        let expectation1 = expectation(forNotification: .deviceMuteDidChange, object: nullDevice) { notification -> Bool in
            guard let channel = notification.userInfo?["channel"] as? UInt32 else { return false }
            guard let scope = notification.userInfo?["scope"] as? Scope else { return false }
            guard scope == .output, channel == 0 else { return false }

            return true
        }

        expectation1.expectationDescription = "device output volumes should change"

        nullDevice.setMute(true, channel: 0, scope: .output)

        waitForExpectations(timeout: 5)

        let expectation2 = expectation(forNotification: .deviceMuteDidChange, object: nullDevice) { notification -> Bool in
            guard let channel = notification.userInfo?["channel"] as? UInt32 else { return false }
            guard let scope = notification.userInfo?["scope"] as? Scope else { return false }
            guard scope == .input, channel == 0 else { return false }

            return true
        }

        expectation2.expectationDescription = "device input volumes should change"

        nullDevice.setMute(true, channel: 0, scope: .input)

        waitForExpectations(timeout: 5)

        XCTAssertTrue(nullDevice.isMuted(channel: 0, scope: .output) ?? false)
        XCTAssertTrue(nullDevice.isMuted(channel: 0, scope: .input) ?? false)
    }
}
