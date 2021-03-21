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
                guard aggregateDevice == self.simplyCA.defaultInputDevice else { return }

                print("defaultInputDeviceChanged?")

                expectation2.fulfill()
            },

            NotificationCenter.default.addObserver(forName: Notifications.defaultOutputDeviceChanged.name,
                                                   object: nil, queue: .main) { (notification) in
                guard aggregateDevice == self.simplyCA.defaultOutputDevice else { return }

                print("defaultOutputDeviceChanged?")

                expectation3.fulfill()
            },

            NotificationCenter.default.addObserver(forName: Notifications.defaultSystemOutputDeviceChanged.name,
                                                   object: nil, queue: .main) { (notification) in
                guard aggregateDevice == self.simplyCA.defaultSystemOutputDevice else { return }

                print("defaultSystemOutputDeviceChanged?")

                expectation4.fulfill()
            }
        ])

        aggregateDevice = simplyCA.createAggregateDevice(masterDeviceUID: nullDevice.uid!,
                                                         secondDeviceUID: nil,
                                                         named: expectedName,
                                                         uid: expectedUID)
        XCTAssertNotNil(aggregateDevice)

        aggregateDevice?.setAsDefaultInputDevice()
        XCTAssertEqual(aggregateDevice, simplyCA.defaultInputDevice)

        aggregateDevice?.setAsDefaultOutputDevice()
        XCTAssertEqual(aggregateDevice, simplyCA.defaultOutputDevice)

        aggregateDevice?.setAsDefaultSystemDevice()
        XCTAssertEqual(aggregateDevice, simplyCA.defaultSystemOutputDevice)

        waitForExpectations(timeout: 5)

        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }

        observers.removeAll()

        if let aggregateDevice = aggregateDevice {
            XCTAssertEqual(noErr, simplyCA.removeAggregateDevice(id: aggregateDevice.id))
        }
    }
}
