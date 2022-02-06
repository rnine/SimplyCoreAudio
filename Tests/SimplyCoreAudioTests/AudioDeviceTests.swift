@testable import SimplyCoreAudio
import XCTest

final class AudioDeviceTests: SCATestCase {
    func testDeviceLookUp() throws {
        let device = try getNullDevice()
        let deviceUID = try XCTUnwrap(device.uid)

        XCTAssertEqual(AudioDevice.lookup(by: device.id), device)
        XCTAssertEqual(AudioDevice.lookup(by: deviceUID), device)
    }

    func testSettingDefaultDevice() throws {
        let device = try getNullDevice()

        device.isDefaultInputDevice = true

        XCTAssertTrue(device.isDefaultInputDevice)
        XCTAssertEqual(simplyCA.defaultInputDevice, device)

        device.isDefaultOutputDevice = true

        XCTAssertTrue(device.isDefaultOutputDevice)
        XCTAssertEqual(simplyCA.defaultOutputDevice, device)

        device.isDefaultSystemOutputDevice = true

        XCTAssertTrue(device.isDefaultSystemOutputDevice)
        XCTAssertEqual(simplyCA.defaultSystemOutputDevice, device)
    }

    func testGeneralDeviceInformation() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.name, "Null Audio Device")
        XCTAssertEqual(device.manufacturer, "Apple Inc.")
        XCTAssertEqual(device.uid, "NullAudioDevice_UID")
        XCTAssertEqual(device.modelUID, "NullAudioDevice_ModelUID")
        XCTAssertEqual(device.configurationApplication, "com.apple.audio.AudioMIDISetup")
        XCTAssertEqual(device.transportType, .virtual)

        XCTAssertFalse(device.isInputOnlyDevice)
        XCTAssertFalse(device.isOutputOnlyDevice)
        XCTAssertFalse(device.isHidden)

        XCTAssertNil(device.isJackConnected(scope: .output))
        XCTAssertNil(device.isJackConnected(scope: .input))

        XCTAssertTrue(device.isAlive)
        XCTAssertFalse(device.isRunning)
        XCTAssertFalse(device.isRunningSomewhere)

        XCTAssertEqual(device.channels(scope: .output), 2)
        XCTAssertEqual(device.channels(scope: .input), 2)

        XCTAssertEqual(device.name(channel: 0, scope: .output), "Master")
        XCTAssertEqual(device.name(channel: 1, scope: .output), "Left")
        XCTAssertEqual(device.name(channel: 2, scope: .output), "Right")

        XCTAssertEqual(device.name(channel: 0, scope: .input), "Master")
        XCTAssertEqual(device.name(channel: 1, scope: .input), "Left")
        XCTAssertEqual(device.name(channel: 2, scope: .input), "Right")

        XCTAssertNotNil(device.ownedObjectIDs)
        XCTAssertNotNil(device.controlList)
        XCTAssertNotNil(device.relatedDevices)
    }

    func testLFE() throws {
        let device = try getNullDevice()

        XCTAssertNil(device.shouldOwniSub)
        device.shouldOwniSub = true
        XCTAssertNil(device.shouldOwniSub)

        XCTAssertNil(device.lfeMute)
        device.lfeMute = true
        XCTAssertNil(device.lfeMute)

        XCTAssertNil(device.lfeVolume)
        device.lfeVolume = 1.0
        XCTAssertNil(device.lfeVolume)

        XCTAssertNil(device.lfeVolumeDecibels)
        device.lfeVolumeDecibels = 6.0
        XCTAssertNil(device.lfeVolumeDecibels)
    }

    func testInputOutputLayout() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.layoutChannels(scope: .output), 2)
        XCTAssertEqual(device.layoutChannels(scope: .input), 2)

        XCTAssertEqual(device.channels(scope: .output), 2)
        XCTAssertEqual(device.channels(scope: .input), 2)

        XCTAssertFalse(device.isInputOnlyDevice)
        XCTAssertFalse(device.isOutputOnlyDevice)
    }

    func testVolumeInfo() throws {
        let device = try getNullDevice()
        var volumeInfo: VolumeInfo!

        XCTAssertTrue(device.setMute(false, channel: 0, scope: .output))

        volumeInfo = try XCTUnwrap(device.volumeInfo(channel: 0, scope: .output))
        XCTAssertEqual(volumeInfo.hasVolume, true)
        XCTAssertEqual(volumeInfo.canSetVolume, true)
        XCTAssertEqual(volumeInfo.canMute, true)
        XCTAssertEqual(volumeInfo.isMuted, false)
        XCTAssertEqual(volumeInfo.canPlayThru, false)
        XCTAssertEqual(volumeInfo.isPlayThruSet, false)

        XCTAssertTrue(device.setVolume(0, channel: 0, scope: .output))
        volumeInfo = try XCTUnwrap(device.volumeInfo(channel: 0, scope: .output))
        XCTAssertEqual(volumeInfo.volume, 0)

        XCTAssertTrue(device.setVolume(0.5, channel: 0, scope: .output))
        volumeInfo = try XCTUnwrap(device.volumeInfo(channel: 0, scope: .output))
        XCTAssertEqual(volumeInfo.volume, 0.5)

        XCTAssertNil(device.volumeInfo(channel: 1, scope: .output))
        XCTAssertNil(device.volumeInfo(channel: 2, scope: .output))
        XCTAssertNil(device.volumeInfo(channel: 3, scope: .output))
        XCTAssertNil(device.volumeInfo(channel: 4, scope: .output))

        XCTAssertNotNil(device.volumeInfo(channel: 0, scope: .input))

        XCTAssertNil(device.volumeInfo(channel: 1, scope: .input))
        XCTAssertNil(device.volumeInfo(channel: 2, scope: .input))
        XCTAssertNil(device.volumeInfo(channel: 3, scope: .input))
        XCTAssertNil(device.volumeInfo(channel: 4, scope: .input))
    }

    func testVolume() throws {
        let device = try getNullDevice()

        // Output scope
        XCTAssertTrue(device.setVolume(0, channel: 0, scope: .output))
        XCTAssertEqual(device.volume(channel: 0, scope: .output), 0)

        XCTAssertTrue(device.setVolume(0.5, channel: 0, scope: .output))
        XCTAssertEqual(device.volume(channel: 0, scope: .output), 0.5)

        XCTAssertFalse(device.setVolume(0.5, channel: 1, scope: .output))
        XCTAssertNil(device.volume(channel: 1, scope: .output))

        XCTAssertFalse(device.setVolume(0.5, channel: 2, scope: .output))
        XCTAssertNil(device.volume(channel: 2, scope: .output))

        // Input scope
        XCTAssertTrue(device.setVolume(0, channel: 0, scope: .input))
        XCTAssertEqual(device.volume(channel: 0, scope: .input), 0)

        XCTAssertTrue(device.setVolume(0.5, channel: 0, scope: .input))
        XCTAssertEqual(device.volume(channel: 0, scope: .input), 0.5)

        XCTAssertFalse(device.setVolume(0.5, channel: 1, scope: .input))
        XCTAssertNil(device.volume(channel: 1, scope: .input))

        XCTAssertFalse(device.setVolume(0.5, channel: 2, scope: .input))
        XCTAssertNil(device.volume(channel: 2, scope: .input))
    }

    func testVolumeInDecibels() throws {
        let device = try getNullDevice()

        // Output scope
        XCTAssertTrue(device.canSetVolume(channel: 0, scope: .output))
        XCTAssertTrue(device.setVolume(0, channel: 0, scope: .output))
        XCTAssertEqual(device.volumeInDecibels(channel: 0, scope: .output), -96)
        XCTAssertTrue(device.setVolume(0.5, channel: 0, scope: .output))
        XCTAssertEqual(device.volumeInDecibels(channel: 0, scope: .output), -70.5)

        XCTAssertFalse(device.canSetVolume(channel: 1, scope: .output))
        XCTAssertFalse(device.setVolume(0.5, channel: 1, scope: .output))
        XCTAssertNil(device.volumeInDecibels(channel: 1, scope: .output))

        XCTAssertFalse(device.canSetVolume(channel: 2, scope: .output))
        XCTAssertFalse(device.setVolume(0.5, channel: 2, scope: .output))
        XCTAssertNil(device.volumeInDecibels(channel: 2, scope: .output))

        // Input scope
        XCTAssertTrue(device.canSetVolume(channel: 0, scope: .input))
        XCTAssertTrue(device.setVolume(0, channel: 0, scope: .input))
        XCTAssertEqual(device.volumeInDecibels(channel: 0, scope: .input), -96)
        XCTAssertTrue(device.setVolume(0.5, channel: 0, scope: .input))
        XCTAssertEqual(device.volumeInDecibels(channel: 0, scope: .input), -70.5)

        XCTAssertFalse(device.canSetVolume(channel: 1, scope: .input))
        XCTAssertFalse(device.setVolume(0.5, channel: 1, scope: .input))
        XCTAssertNil(device.volumeInDecibels(channel: 1, scope: .input))

        XCTAssertFalse(device.canSetVolume(channel: 2, scope: .input))
        XCTAssertFalse(device.setVolume(0.5, channel: 2, scope: .input))
        XCTAssertNil(device.volumeInDecibels(channel: 2, scope: .input))
    }

    func testMute() throws {
        let device = try getNullDevice()

        // Output scope
        XCTAssertTrue(device.canMute(channel: 0, scope: .output))
        XCTAssertTrue(device.setMute(true, channel: 0, scope: .output))
        XCTAssertEqual(device.isMuted(channel: 0, scope: .output), true)
        XCTAssertTrue(device.setMute(false, channel: 0, scope: .output))
        XCTAssertEqual(device.isMuted(channel: 0, scope: .output), false)

        XCTAssertFalse(device.canMute(channel: 1, scope: .output))
        XCTAssertFalse(device.setMute(true, channel: 1, scope: .output))
        XCTAssertNil(device.isMuted(channel: 1, scope: .output))

        XCTAssertFalse(device.canMute(channel: 2, scope: .output))
        XCTAssertFalse(device.setMute(true, channel: 2, scope: .output))
        XCTAssertNil(device.isMuted(channel: 2, scope: .output))

        // Input scope
        XCTAssertTrue(device.canMute(channel: 0, scope: .input))
        XCTAssertTrue(device.setMute(true, channel: 0, scope: .input))
        XCTAssertEqual(device.isMuted(channel: 0, scope: .input), true)
        XCTAssertTrue(device.setMute(false, channel: 0, scope: .input))
        XCTAssertEqual(device.isMuted(channel: 0, scope: .input), false)

        XCTAssertFalse(device.canMute(channel: 1, scope: .input))
        XCTAssertFalse(device.setMute(true, channel: 1, scope: .input))
        XCTAssertNil(device.isMuted(channel: 1, scope: .input))

        XCTAssertFalse(device.canMute(channel: 2, scope: .input))
        XCTAssertFalse(device.setMute(true, channel: 2, scope: .input))
        XCTAssertNil(device.isMuted(channel: 2, scope: .input))
    }

    func testMainChannelMute() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.canMuteMainChannel(scope: .output), true)
        XCTAssertTrue(device.setMute(false, channel: 0, scope: .output))
        XCTAssertEqual(device.isMainChannelMuted(scope: .output), false)
        XCTAssertTrue(device.setMute(true, channel: 0, scope: .output))
        XCTAssertEqual(device.isMainChannelMuted(scope: .output), true)

        XCTAssertEqual(device.canMuteMainChannel(scope: .input), true)
        XCTAssertTrue(device.setMute(false, channel: 0, scope: .input))
        XCTAssertEqual(device.isMainChannelMuted(scope: .input), false)
        XCTAssertTrue(device.setMute(true, channel: 0, scope: .input))
        XCTAssertEqual(device.isMainChannelMuted(scope: .input), true)
    }

    func testPreferredChannelsForStereo() throws {
        let device = try getNullDevice()
        var preferredChannels = try XCTUnwrap(device.preferredChannelsForStereo(scope: .output))

        XCTAssertEqual(preferredChannels.left, 1)
        XCTAssertEqual(preferredChannels.right, 2)

        XCTAssertTrue(device.setPreferredChannelsForStereo(channels: StereoPair(left: 1, right: 1), scope: .output))
        preferredChannels = try XCTUnwrap(device.preferredChannelsForStereo(scope: .output))
        XCTAssertEqual(preferredChannels.left, 1)
        XCTAssertEqual(preferredChannels.right, 1)

        XCTAssertTrue(device.setPreferredChannelsForStereo(channels: StereoPair(left: 2, right: 2), scope: .output))
        preferredChannels = try XCTUnwrap(device.preferredChannelsForStereo(scope: .output))
        XCTAssertEqual(preferredChannels.left, 2)
        XCTAssertEqual(preferredChannels.right, 2)

        XCTAssertTrue(device.setPreferredChannelsForStereo(channels: StereoPair(left: 1, right: 2), scope: .output))
        preferredChannels = try XCTUnwrap(device.preferredChannelsForStereo(scope: .output))
        XCTAssertEqual(preferredChannels.left, 1)
        XCTAssertEqual(preferredChannels.right, 2)
    }

    func testVirtualMainChannels() throws {
        let device = try getNullDevice()

        XCTAssertTrue(device.canSetVirtualMainVolume(scope: .output))
        XCTAssertTrue(device.canSetVirtualMainVolume(scope: .input))

        XCTAssertTrue(device.setVirtualMainVolume(0.0, scope: .output))
        XCTAssertEqual(device.virtualMainVolume(scope: .output), 0.0)
        // XCTAssertEqual(device.virtualMainVolumeInDecibels(scope: .output), -96.0)
        XCTAssertTrue(device.setVirtualMainVolume(0.5, scope: .output))
        XCTAssertEqual(device.virtualMainVolume(scope: .output), 0.5)
        // XCTAssertEqual(device.virtualMainVolumeInDecibels(scope: .output), -70.5)

        XCTAssertTrue(device.setVirtualMainVolume(0.0, scope: .input))
        XCTAssertEqual(device.virtualMainVolume(scope: .input), 0.0)
        // XCTAssertEqual(device.virtualMainVolumeInDecibels(scope: .input), -96.0)
        XCTAssertTrue(device.setVirtualMainVolume(0.5, scope: .input))
        XCTAssertEqual(device.virtualMainVolume(scope: .input), 0.5)
        // XCTAssertEqual(device.virtualMainVolumeInDecibels(scope: .input), -70.5)
    }

    func testVirtualMainBalance() throws {
        let device = try getNullDevice()

        XCTAssertTrue(device.canSetVirtualMainBalance(scope: .output))
        XCTAssertTrue(device.canSetVirtualMainBalance(scope: .input))

        XCTAssertFalse(device.setVirtualMainBalance(0.0, scope: .output))
        XCTAssertNil(device.virtualMainBalance(scope: .output))

        XCTAssertFalse(device.setVirtualMainBalance(0.0, scope: .input))
        XCTAssertNil(device.virtualMainBalance(scope: .input))
    }

    func testSampleRate() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.nominalSampleRates, [44100, 48000])

        XCTAssertTrue(device.setNominalSampleRate(44100))
        sleep(1)
        XCTAssertEqual(device.nominalSampleRate, 44100)
        XCTAssertEqual(device.actualSampleRate, 44100)

        XCTAssertTrue(device.setNominalSampleRate(48000))
        sleep(1)
        XCTAssertEqual(device.nominalSampleRate, 48000)
        XCTAssertEqual(device.actualSampleRate, 48000)
    }

    func testDataSource() throws {
        let device = try getNullDevice()

        XCTAssertNotNil(device.dataSource(scope: .output))
        XCTAssertNotNil(device.dataSource(scope: .input))
    }

    func testDataSources() throws {
        let device = try getNullDevice()

        XCTAssertNotNil(device.dataSources(scope: .output))
        XCTAssertNotNil(device.dataSources(scope: .input))
    }

    func testDataSourceName() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.dataSourceName(dataSourceID: 0, scope: .output), "Data Source Item 0")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 1, scope: .output), "Data Source Item 1")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 2, scope: .output), "Data Source Item 2")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 3, scope: .output), "Data Source Item 3")
        XCTAssertNil(device.dataSourceName(dataSourceID: 4, scope: .output))

        XCTAssertEqual(device.dataSourceName(dataSourceID: 0, scope: .input), "Data Source Item 0")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 1, scope: .input), "Data Source Item 1")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 2, scope: .input), "Data Source Item 2")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 3, scope: .input), "Data Source Item 3")
        XCTAssertNil(device.dataSourceName(dataSourceID: 4, scope: .input))
    }

    func testClockSource() throws {
        let device = try getNullDevice()

        XCTAssertNil(device.clockSourceID)
        XCTAssertNil(device.clockSourceIDs)
        XCTAssertNil(device.clockSourceName)
        XCTAssertNil(device.clockSourceNames)
        XCTAssertNil(device.clockSourceName(clockSourceID: 0))
        XCTAssertFalse(device.setClockSourceID(0))
    }

    func testTotalLatency() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.latency(scope: .output), 512)
        XCTAssertEqual(device.latency(scope: .input), 512)
    }

    func testSafetyOffset() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.safetyOffset(scope: .output), 0)
        XCTAssertEqual(device.safetyOffset(scope: .input), 0)
    }
    
    func testBufferFrameSize() throws {
        let device = try getNullDevice()

        // The IO buffer is generally 512 by default. Also the case
        // for the NullAudio.driver
        XCTAssertEqual(device.bufferFrameSize(scope: .output), 512)
        XCTAssertEqual(device.bufferFrameSize(scope: .input), 512)
    }

    func testHogMode() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.hogModePID, -1)
        XCTAssertTrue(device.setHogMode())
        XCTAssertEqual(device.hogModePID, pid_t(ProcessInfo.processInfo.processIdentifier))
        XCTAssertTrue(device.unsetHogMode())
        XCTAssertEqual(device.hogModePID, -1)
    }

//    func testVolumeConversion() throws {
//        let device = try GetDevice()
//
//        XCTAssertEqual(device.scalarToDecibels(volume: 0, channel: 0, scope: .output), -96.0)
//        XCTAssertEqual(device.scalarToDecibels(volume: 1, channel: 0, scope: .output), 6.0)
//
//        XCTAssertEqual(device.decibelsToScalar(volume: -96.0, channel: 0, scope: .output), 0)
//        XCTAssertEqual(device.decibelsToScalar(volume: 6.0, channel: 0, scope: .output), 1)
//    }

    func testStreams() throws {
        let device = try getNullDevice()

        XCTAssertNotNil(device.streams(scope: .output))
        XCTAssertNotNil(device.streams(scope: .input))
    }

    func testCreateAndDestroyAggregateDevice() throws {
        let nullDevice = try getNullDevice()

        guard let device = simplyCA.createAggregateDevice(mainDevice: nullDevice,
                                                          secondDevice: nil,
                                                          named: "testCreateAggregateAudioDevice",
                                                          uid: "testCreateAggregateAudioDevice-12345")
        else {
            XCTFail("Failed creating device")
            return
        }

        XCTAssertTrue(device.isAggregateDevice)
        XCTAssertTrue(device.ownedAggregateDevices?.count == 1)

        wait(for: 2)

        let error = simplyCA.removeAggregateDevice(id: device.id)
        XCTAssertTrue(error == noErr, "Failed removing device")

        wait(for: 2)
    }
}
