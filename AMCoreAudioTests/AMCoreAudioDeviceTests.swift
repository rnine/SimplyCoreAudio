//
//  AMCoreAudioDeviceTests.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 14/08/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import XCTest
import AMCoreAudio

class AMCoreAudioDeviceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInvalidDeviceUIDInitializer() {
        let invalidDevice = AMCoreAudioDevice(deviceUID: "INVALID-ID")

        XCTAssertNil(invalidDevice)
    }

    func testValidDeviceUIDInitializer() {
        if let someAudioDevice: AMCoreAudioDevice = AMCoreAudioDevice.allDevices().first,
            let validDeviceUID = someAudioDevice.deviceUID() {
                let validDevice = AMCoreAudioDevice(deviceUID: validDeviceUID)

                XCTAssertNotNil(validDevice)
                XCTAssertEqual(validDevice!.deviceUID(), validDeviceUID)
        }
    }

    func testAllDevices() {
        let allDeviceIDs = AMCoreAudioDevice.allDeviceIDs()
        let allDevices = AMCoreAudioDevice.allDevices()

        XCTAssertEqual(allDeviceIDs.count, allDevices.count)
        XCTAssertEqual(allDeviceIDs, allDevices.map { $0.deviceID })
    }

    func testAllInputDevices() {
        let allInputDevices = AMCoreAudioDevice.allInputDevices()

        for inputDevice in allInputDevices {
            if let channels = inputDevice.channelsForDirection(Direction.Recording) {
                XCTAssertGreaterThan(channels, 0)
            } else {
                XCTAssert(false, "Expected a value.")
            }
        }
    }

    func testAllOutputDevices() {
        let allOutputDevices = AMCoreAudioDevice.allOutputDevices()

        for outputDevice in allOutputDevices {
            if let channels = outputDevice.channelsForDirection(Direction.Playback) {
                XCTAssertGreaterThan(channels, 0)
            } else {
                XCTAssert(false, "Expected a value.")
            }
        }
    }

    func testNominalSampleRate() {
        if let someAudioDevice: AMCoreAudioDevice = AMCoreAudioDevice.allDevices().first {
            if let nominalSampleRates = someAudioDevice.nominalSampleRates(),
                   nominalSampleRate = someAudioDevice.nominalSampleRate() {
                XCTAssertTrue(nominalSampleRates.contains(nominalSampleRate), "Expected \(nominalSampleRates) to contain \(nominalSampleRate).")
            } else {
                XCTAssert(false, "Audio device \(someAudioDevice.description) does not support any sample rate.")
            }
        } else {
            print("(!) No audio devices found.")
        }
    }

    func testVolumeForChannelForOutputDirection() {
        let devices = AMCoreAudioDevice.allOutputDevices()

        if devices.count == 0 {
            print("(!) No output audio devices found.")
        }

        for device in devices {
            if let channels = device.channelsForDirection(.Playback) {
                for channel in 0...channels {
                    if let volume = device.volumeForChannel(channel, andDirection: .Playback) {
                        XCTAssertTrue(volume >= 0)
                    } else {
                        print("(!) \(device) volume for channel \(channel) not available.")
                    }
                }
            } else {
                XCTAssert(false, "Expected output device to contain output channels.")
            }
        }
    }

    func testVolumeForChannelForInputDirection() {
        let devices = AMCoreAudioDevice.allInputDevices()

        if devices.count == 0 {
            print("(!) No input audio devices found.")
        }

        for device in devices {
            if let channels = device.channelsForDirection(.Recording) {
                for channel in 0...channels {
                    if let volume = device.volumeForChannel(channel, andDirection: .Recording) {
                        XCTAssertTrue(volume >= 0)
                    } else {
                        print("(!) \(device) volume for channel \(channel) not available.")
                    }
                }
            } else {
                XCTAssert(false, "Expected input device to contain input channels.")
            }
        }
    }

    func testPreferredStereoChannels() {
        let devices = AMCoreAudioDevice.allDevices()

        if devices.count == 0 {
            print("(!) No audio devices found.")
            return
        }

        for device in devices {
            if let preferredStereoChannels = device.preferredStereoChannelsForDirection(.Playback) {
                print("(*) \(device) preferred stereo channels for playback: \(preferredStereoChannels)")
            }

            if let preferredStereoChannels = device.preferredStereoChannelsForDirection(.Recording) {
                print("(*) \(device) preferred stereo channels for recording: \(preferredStereoChannels)")
            }
        }
    }
}
