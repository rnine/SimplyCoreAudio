//
//  NotificationTests.swift
//  
//
//  Created by Ruben Nine on 21/3/21.
//

import XCTest
@testable import SimplyCoreAudio

class NotificationTests: SCATestCase {
    func testHardwareNotifications() throws {
        let nullDevice = try getNullDevice()
        var aggregateDevice: AudioDevice?

        let expectation1 = self.expectation(description: "aggregate device should be added to device list")
        let expectation2 = self.expectation(description: "aggregate device should become default input device")
        let expectation3 = self.expectation(description: "aggregate device should become default output device")
        let expectation4 = self.expectation(description: "aggregate device should become default system output device")

        let expectedName = "NullDeviceAggregate"
        let expectedUID = "NullDeviceAggregate_UID"

        var observers = [NSObjectProtocol]()

        observers.append(contentsOf: [
            NotificationCenter.default.addObserver(forName: Notifications.deviceListChanged.name,
                                                   object: nil,
                                                   queue: .main) { (notification) in
                guard let addedDevices = notification.userInfo?["addedDevices"] as? [AudioDevice] else { return }
                guard let firstAddedDevice = addedDevices.first else { return }
                guard firstAddedDevice.uid == expectedUID else { return }
                guard firstAddedDevice.name == expectedName else { return }

                expectation1.fulfill()
            },

            NotificationCenter.default.addObserver(forName: Notifications.defaultInputDeviceChanged.name,
                                                   object: nil, queue: .main) { (notification) in
                expectation2.fulfill()
            },

            NotificationCenter.default.addObserver(forName: Notifications.defaultOutputDeviceChanged.name,
                                                   object: nil, queue: .main) { (notification) in
                expectation3.fulfill()
            },

            NotificationCenter.default.addObserver(forName: Notifications.defaultSystemOutputDeviceChanged.name,
                                                   object: nil, queue: .main) { (notification) in
                expectation4.fulfill()
            }
        ])

        aggregateDevice = simplyCA.createAggregateDevice(masterDeviceUID: nullDevice.uid!,
                                                         secondDeviceUID: nil,
                                                         named: expectedName,
                                                         uid: expectedUID)
        XCTAssertNotNil(aggregateDevice)

        aggregateDevice?.setAsDefaultInputDevice()
        aggregateDevice?.setAsDefaultOutputDevice()
        aggregateDevice?.setAsDefaultSystemDevice()

        waitForExpectations(timeout: 5)

        XCTAssertEqual(aggregateDevice, simplyCA.defaultInputDevice)
        XCTAssertEqual(aggregateDevice, simplyCA.defaultOutputDevice)
        XCTAssertEqual(aggregateDevice, simplyCA.defaultSystemOutputDevice)

        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }

        observers.removeAll()

        if let aggregateDevice = aggregateDevice {
            XCTAssertEqual(noErr, simplyCA.removeAggregateDevice(id: aggregateDevice.id))
        }
    }

    func testDeviceSamplerateDidChangeNotification() throws {
        let nullDevice = try getNullDevice()
        let baseSamplerate = 44100.0
        let targetSamplerate = 48000.0

        XCTAssertEqual(nullDevice.nominalSampleRate, baseSamplerate)
        XCTAssertTrue(nullDevice.nominalSampleRates!.contains(targetSamplerate))

        let expectation = self.expectation(description: "device samplerate should change")

        var observers = [NSObjectProtocol]()

        observers.append(
            NotificationCenter.default.addObserver(forName: Notifications.deviceNominalSampleRateDidChange.name,
                                                   object: nil,
                                                   queue: .main) { (notification) in
                expectation.fulfill()
            }
        )

        nullDevice.setNominalSampleRate(targetSamplerate)

        waitForExpectations(timeout: 5)

        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }

        observers.removeAll()

        XCTAssertEqual(nullDevice.nominalSampleRate, targetSamplerate)
    }

    func testDeviceVolumeDidChangeNotification() throws {
        let nullDevice = try getNullDevice()

        let expectation1 = self.expectation(description: "device output volume should change")
        let expectation2 = self.expectation(description: "device input volume should change")

        var observers = [NSObjectProtocol]()

        observers.append(
            NotificationCenter.default.addObserver(forName: Notifications.deviceVolumeDidChange.name,
                                                   object: nil,
                                                   queue: .main) { (notification) in
                guard let channel = notification.userInfo?["channel"] as? UInt32 else { return }
                guard let scope = notification.userInfo?["scope"] as? Scope else { return }

                if scope == .output, channel == 0 {
                    expectation1.fulfill()
                }

                if scope == .input, channel == 0 {
                    expectation2.fulfill()
                }
            }
        )

        nullDevice.setVirtualMasterVolume(1, scope: .output)
        nullDevice.setVirtualMasterVolume(1, scope: .input)

        waitForExpectations(timeout: 5)

        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }

        observers.removeAll()

        XCTAssertEqual(nullDevice.virtualMasterVolume(scope: .output), 1)
        XCTAssertEqual(nullDevice.virtualMasterVolume(scope: .input), 1)
    }

    func testDeviceMuteDidChangeNotification() throws {
        let nullDevice = try getNullDevice()

        let expectation1 = self.expectation(description: "device output volume should mute")
        let expectation2 = self.expectation(description: "device input volume should mute")

        var observers = [NSObjectProtocol]()

        observers.append(
            NotificationCenter.default.addObserver(forName: Notifications.deviceMuteDidChange.name,
                                                   object: nil,
                                                   queue: .main) { (notification) in
                guard let channel = notification.userInfo?["channel"] as? UInt32 else { return }
                guard let scope = notification.userInfo?["scope"] as? Scope else { return }

                if scope == .output, channel == 0 {
                    expectation1.fulfill()
                }

                if scope == .input, channel == 0 {
                    expectation2.fulfill()
                }
            }
        )

        nullDevice.setMute(true, channel: 0, scope: .output)
        nullDevice.setMute(true, channel: 0, scope: .input)

        waitForExpectations(timeout: 5)

        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }

        observers.removeAll()

        XCTAssertTrue(nullDevice.isMuted(channel: 0, scope: .output) ?? false)
        XCTAssertTrue(nullDevice.isMuted(channel: 0, scope: .input) ?? false)
    }
}
