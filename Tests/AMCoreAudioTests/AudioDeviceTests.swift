import XCTest
@testable import AMCoreAudio

final class AudioDeviceTests: XCTestCase {
    let defaultOutputDevice = AudioDevice.defaultOutputDevice()
    let defaultInputDevice = AudioDevice.defaultInputDevice()
    let defaultSystemOutputDevice = AudioDevice.defaultSystemOutputDevice()

    override func setUp() {
        super.setUp()

        ResetDefaultDevices()
        try? ResetDeviceState()
    }

    override func tearDown() {
        super.tearDown()

        ResetDefaultDevices()
        try? ResetDeviceState()
    }

    func testDeviceLookUp() throws {
        let device = try GetDevice()
        let deviceUID = try XCTUnwrap(device.uid)

        XCTAssertEqual(AudioDevice.lookup(by: device.id), device)
        XCTAssertEqual(AudioDevice.lookup(by: deviceUID), device)
    }

    func testDeviceEnumeration() throws {
        let device = try GetDevice()

        XCTAssertTrue(AudioDevice.allDevices().contains(device))
        XCTAssertTrue(AudioDevice.allDeviceIDs().contains(device.id))
        XCTAssertTrue(AudioDevice.allInputDevices().contains(device))
        XCTAssertTrue(AudioDevice.allOutputDevices().contains(device))
    }

    func testSettingDefaultDevice() throws {
        let device = try GetDevice()

        XCTAssertTrue(device.setAsDefaultSystemDevice())
        XCTAssertEqual(AudioDevice.defaultSystemOutputDevice(), device)

        XCTAssertTrue(device.setAsDefaultOutputDevice())
        XCTAssertEqual(AudioDevice.defaultOutputDevice(), device)

        XCTAssertTrue(device.setAsDefaultInputDevice())
        XCTAssertEqual(AudioDevice.defaultInputDevice(), device)
    }

    func testGeneralDeviceInformation() throws {
        let device = try GetDevice()

        XCTAssertEqual(device.name, "Null Audio Device")
        XCTAssertEqual(device.manufacturer, "Apple Inc.")
        XCTAssertEqual(device.uid, "NullAudioDevice_UID")
        XCTAssertEqual(device.modelUID, "NullAudioDevice_ModelUID")
        XCTAssertEqual(device.configurationApplication, "com.apple.audio.AudioMIDISetup")
        XCTAssertEqual(device.transportType, TransportType.virtual)

        XCTAssertFalse(device.isInputOnlyDevice())
        XCTAssertFalse(device.isOutputOnlyDevice())
        XCTAssertFalse(device.isHidden())

        XCTAssertNil(device.isJackConnected(direction: .playback))
        XCTAssertNil(device.isJackConnected(direction: .recording))

        XCTAssertTrue(device.isAlive())
        XCTAssertFalse(device.isRunning())
        XCTAssertFalse(device.isRunningSomewhere())

        XCTAssertNil(device.name(channel: 0, direction: .playback))
        XCTAssertNil(device.name(channel: 1, direction: .playback))
        XCTAssertNil(device.name(channel: 2, direction: .playback))
        XCTAssertNil(device.name(channel: 0, direction: .recording))
        XCTAssertNil(device.name(channel: 1, direction: .recording))
        XCTAssertNil(device.name(channel: 2, direction: .recording))

        XCTAssertNotNil(device.ownedObjectIDs())
        XCTAssertNotNil(device.controlList())
        XCTAssertNotNil(device.relatedDevices())
    }

    func testLFE() throws {
        let device = try GetDevice()

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
        let device = try GetDevice()

        XCTAssertEqual(device.layoutChannels(direction: .playback), 2)
        XCTAssertEqual(device.layoutChannels(direction: .recording), 2)

        XCTAssertEqual(device.channels(direction: .playback), 2)
        XCTAssertEqual(device.channels(direction: .recording), 2)

        XCTAssertFalse(device.isInputOnlyDevice())
        XCTAssertFalse(device.isOutputOnlyDevice())
    }

    func testVolumeInfo() throws {
        let device = try GetDevice()
        var volumeInfo: VolumeInfo!

        XCTAssertTrue(device.setMute(false, channel: 0, direction: .playback))

        volumeInfo = try XCTUnwrap(device.volumeInfo(channel: 0, direction: .playback))
        XCTAssertEqual(volumeInfo.hasVolume, true)
        XCTAssertEqual(volumeInfo.canSetVolume, true)
        XCTAssertEqual(volumeInfo.canMute, true)
        XCTAssertEqual(volumeInfo.isMuted, false)
        XCTAssertEqual(volumeInfo.canPlayThru, false)
        XCTAssertEqual(volumeInfo.isPlayThruSet, false)

        XCTAssertTrue(device.setVolume(0, channel: 0, direction: .playback))
        volumeInfo = try XCTUnwrap(device.volumeInfo(channel: 0, direction: .playback))
        XCTAssertEqual(volumeInfo.volume, 0)

        XCTAssertTrue(device.setVolume(0.5, channel: 0, direction: .playback))
        volumeInfo = try XCTUnwrap(device.volumeInfo(channel: 0, direction: .playback))
        XCTAssertEqual(volumeInfo.volume, 0.5)

        XCTAssertNil(device.volumeInfo(channel: 1, direction: .playback))
        XCTAssertNil(device.volumeInfo(channel: 2, direction: .playback))
        XCTAssertNil(device.volumeInfo(channel: 3, direction: .playback))
        XCTAssertNil(device.volumeInfo(channel: 4, direction: .playback))

        XCTAssertNotNil(device.volumeInfo(channel: 0, direction: .recording))

        XCTAssertNil(device.volumeInfo(channel: 1, direction: .recording))
        XCTAssertNil(device.volumeInfo(channel: 2, direction: .recording))
        XCTAssertNil(device.volumeInfo(channel: 3, direction: .recording))
        XCTAssertNil(device.volumeInfo(channel: 4, direction: .recording))
    }

    func testVolume() throws {
        let device = try GetDevice()

        // Playback direction
        XCTAssertTrue(device.setVolume(0, channel: 0, direction: .playback))
        XCTAssertEqual(device.volume(channel: 0, direction: .playback), 0)

        XCTAssertTrue(device.setVolume(0.5, channel: 0, direction: .playback))
        XCTAssertEqual(device.volume(channel: 0, direction: .playback), 0.5)

        XCTAssertFalse(device.setVolume(0.5, channel: 1, direction: .playback))
        XCTAssertNil(device.volume(channel: 1, direction: .playback))

        XCTAssertFalse(device.setVolume(0.5, channel: 2, direction: .playback))
        XCTAssertNil(device.volume(channel: 2, direction: .playback))

        // Recording direction
        XCTAssertTrue(device.setVolume(0, channel: 0, direction: .recording))
        XCTAssertEqual(device.volume(channel: 0, direction: .recording), 0)

        XCTAssertTrue(device.setVolume(0.5, channel: 0, direction: .recording))
        XCTAssertEqual(device.volume(channel: 0, direction: .recording), 0.5)

        XCTAssertFalse(device.setVolume(0.5, channel: 1, direction: .recording))
        XCTAssertNil(device.volume(channel: 1, direction: .recording))

        XCTAssertFalse(device.setVolume(0.5, channel: 2, direction: .recording))
        XCTAssertNil(device.volume(channel: 2, direction: .recording))
    }

    func testVolumeInDecibels() throws {
        let device = try GetDevice()

        // Playback direction
        XCTAssertTrue(device.canSetVolume(channel: 0, direction: .playback))
        XCTAssertTrue(device.setVolume(0, channel: 0, direction: .playback))
        XCTAssertEqual(device.volumeInDecibels(channel: 0, direction: .playback), -96)
        XCTAssertTrue(device.setVolume(0.5, channel: 0, direction: .playback))
        XCTAssertEqual(device.volumeInDecibels(channel: 0, direction: .playback), -70.5)

        XCTAssertFalse(device.canSetVolume(channel: 1, direction: .playback))
        XCTAssertFalse(device.setVolume(0.5, channel: 1, direction: .playback))
        XCTAssertNil(device.volumeInDecibels(channel: 1, direction: .playback))

        XCTAssertFalse(device.canSetVolume(channel: 2, direction: .playback))
        XCTAssertFalse(device.setVolume(0.5, channel: 2, direction: .playback))
        XCTAssertNil(device.volumeInDecibels(channel: 2, direction: .playback))

        // Recording direction
        XCTAssertTrue(device.canSetVolume(channel: 0, direction: .recording))
        XCTAssertTrue(device.setVolume(0, channel: 0, direction: .recording))
        XCTAssertEqual(device.volumeInDecibels(channel: 0, direction: .recording), -96)
        XCTAssertTrue(device.setVolume(0.5, channel: 0, direction: .recording))
        XCTAssertEqual(device.volumeInDecibels(channel: 0, direction: .recording), -70.5)

        XCTAssertFalse(device.canSetVolume(channel: 1, direction: .recording))
        XCTAssertFalse(device.setVolume(0.5, channel: 1, direction: .recording))
        XCTAssertNil(device.volumeInDecibels(channel: 1, direction: .recording))

        XCTAssertFalse(device.canSetVolume(channel: 2, direction: .recording))
        XCTAssertFalse(device.setVolume(0.5, channel: 2, direction: .recording))
        XCTAssertNil(device.volumeInDecibels(channel: 2, direction: .recording))
    }

    func testMute() throws {
        let device = try GetDevice()

        // Playback direction
        XCTAssertTrue(device.canMute(channel: 0, direction: .playback))
        XCTAssertTrue(device.setMute(true, channel: 0, direction: .playback))
        XCTAssertEqual(device.isMuted(channel: 0, direction: .playback), true)
        XCTAssertTrue(device.setMute(false, channel: 0, direction: .playback))
        XCTAssertEqual(device.isMuted(channel: 0, direction: .playback), false)

        XCTAssertFalse(device.canMute(channel: 1, direction: .playback))
        XCTAssertFalse(device.setMute(true, channel: 1, direction: .playback))
        XCTAssertNil(device.isMuted(channel: 1, direction: .playback))

        XCTAssertFalse(device.canMute(channel: 2, direction: .playback))
        XCTAssertFalse(device.setMute(true, channel: 2, direction: .playback))
        XCTAssertNil(device.isMuted(channel: 2, direction: .playback))

        // Recording direction
        XCTAssertTrue(device.canMute(channel: 0, direction: .recording))
        XCTAssertTrue(device.setMute(true, channel: 0, direction: .recording))
        XCTAssertEqual(device.isMuted(channel: 0, direction: .recording), true)
        XCTAssertTrue(device.setMute(false, channel: 0, direction: .recording))
        XCTAssertEqual(device.isMuted(channel: 0, direction: .recording), false)

        XCTAssertFalse(device.canMute(channel: 1, direction: .recording))
        XCTAssertFalse(device.setMute(true, channel: 1, direction: .recording))
        XCTAssertNil(device.isMuted(channel: 1, direction: .recording))

        XCTAssertFalse(device.canMute(channel: 2, direction: .recording))
        XCTAssertFalse(device.setMute(true, channel: 2, direction: .recording))
        XCTAssertNil(device.isMuted(channel: 2, direction: .recording))
    }

    func testMasterChannelMute() throws {
        let device = try GetDevice()

        XCTAssertEqual(device.canMuteMasterChannel(direction: .playback), true)
        XCTAssertTrue(device.setMute(false, channel: 0, direction: .playback))
        XCTAssertEqual(device.isMasterChannelMuted(direction: .playback), false)
        XCTAssertTrue(device.setMute(true, channel: 0, direction: .playback))
        XCTAssertEqual(device.isMasterChannelMuted(direction: .playback), true)

        XCTAssertEqual(device.canMuteMasterChannel(direction: .recording), true)
        XCTAssertTrue(device.setMute(false, channel: 0, direction: .recording))
        XCTAssertEqual(device.isMasterChannelMuted(direction: .recording), false)
        XCTAssertTrue(device.setMute(true, channel: 0, direction: .recording))
        XCTAssertEqual(device.isMasterChannelMuted(direction: .recording), true)
    }

    func testPreferredChannelsForStereo() throws {
        let device = try GetDevice()
        var preferredChannels = try XCTUnwrap(device.preferredChannelsForStereo(direction: .playback))

        XCTAssertEqual(preferredChannels.left, 1)
        XCTAssertEqual(preferredChannels.right, 2)

        XCTAssertTrue(device.setPreferredChannelsForStereo(channels: StereoPair(left: 1, right: 1), direction: .playback))
        preferredChannels = try XCTUnwrap(device.preferredChannelsForStereo(direction: .playback))
        XCTAssertEqual(preferredChannels.left, 1)
        XCTAssertEqual(preferredChannels.right, 1)

        XCTAssertTrue(device.setPreferredChannelsForStereo(channels: StereoPair(left: 2, right: 2), direction: .playback))
        preferredChannels = try XCTUnwrap(device.preferredChannelsForStereo(direction: .playback))
        XCTAssertEqual(preferredChannels.left, 2)
        XCTAssertEqual(preferredChannels.right, 2)

        XCTAssertTrue(device.setPreferredChannelsForStereo(channels: StereoPair(left: 1, right: 2), direction: .playback))
        preferredChannels = try XCTUnwrap(device.preferredChannelsForStereo(direction: .playback))
        XCTAssertEqual(preferredChannels.left, 1)
        XCTAssertEqual(preferredChannels.right, 2)
    }

    func testVirtualMasterChannels() throws {
        let device = try GetDevice()

        XCTAssertTrue(device.canSetVirtualMasterVolume(direction: .playback))
        XCTAssertTrue(device.canSetVirtualMasterVolume(direction: .recording))

        XCTAssertTrue(device.setVirtualMasterVolume(0.0, direction: .playback))
        XCTAssertEqual(device.virtualMasterVolume(direction: .playback), 0.0)
        XCTAssertEqual(device.virtualMasterVolumeInDecibels(direction: .playback), -96.0)
        XCTAssertTrue(device.setVirtualMasterVolume(0.5, direction: .playback))
        XCTAssertEqual(device.virtualMasterVolume(direction: .playback), 0.5)
        XCTAssertEqual(device.virtualMasterVolumeInDecibels(direction: .playback), -70.5)

        XCTAssertTrue(device.setVirtualMasterVolume(0.0, direction: .recording))
        XCTAssertEqual(device.virtualMasterVolume(direction: .recording), 0.0)
        XCTAssertEqual(device.virtualMasterVolumeInDecibels(direction: .recording), -96.0)
        XCTAssertTrue(device.setVirtualMasterVolume(0.5, direction: .recording))
        XCTAssertEqual(device.virtualMasterVolume(direction: .recording), 0.5)
        XCTAssertEqual(device.virtualMasterVolumeInDecibels(direction: .recording), -70.5)
    }

    func testVirtualMasterBalance() throws {
        let device = try GetDevice()

        XCTAssertFalse(device.setVirtualMasterBalance(0.0, direction: .playback))
        XCTAssertNil(device.virtualMasterBalance(direction: .playback))

        XCTAssertFalse(device.setVirtualMasterBalance(0.0, direction: .recording))
        XCTAssertNil(device.virtualMasterBalance(direction: .recording))
    }

    func testSampleRate() throws {
        let device = try GetDevice()

        XCTAssertEqual(device.nominalSampleRates(), [44100, 48000])

        XCTAssertTrue(device.setNominalSampleRate(44100))
        sleep(1)
        XCTAssertEqual(device.nominalSampleRate(), 44100)
        XCTAssertEqual(device.actualSampleRate(), 44100)

        XCTAssertTrue(device.setNominalSampleRate(48000))
        sleep(1)
        XCTAssertEqual(device.nominalSampleRate(), 48000)
        XCTAssertEqual(device.actualSampleRate(), 48000)
    }

    func testDataSource() throws {
        let device = try GetDevice()

        XCTAssertNotNil(device.dataSource(direction: .playback))
        XCTAssertNotNil(device.dataSource(direction: .recording))
    }

    func testDataSources() throws {
        let device = try GetDevice()

        XCTAssertNotNil(device.dataSources(direction: .playback))
        XCTAssertNotNil(device.dataSources(direction: .recording))
    }

    func testDataSourceName() throws {
        let device = try GetDevice()

        XCTAssertEqual(device.dataSourceName(dataSourceID: 0, direction: .playback), "Data Source Item 0")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 1, direction: .playback), "Data Source Item 1")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 2, direction: .playback), "Data Source Item 2")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 3, direction: .playback), "Data Source Item 3")
        XCTAssertNil(device.dataSourceName(dataSourceID: 4, direction: .playback))

        XCTAssertEqual(device.dataSourceName(dataSourceID: 0, direction: .recording), "Data Source Item 0")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 1, direction: .recording), "Data Source Item 1")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 2, direction: .recording), "Data Source Item 2")
        XCTAssertEqual(device.dataSourceName(dataSourceID: 3, direction: .recording), "Data Source Item 3")
        XCTAssertNil(device.dataSourceName(dataSourceID: 4, direction: .recording))
    }

    func testClockSource() throws {
        let device = try GetDevice()

        XCTAssertNil(device.clockSourceID())
        XCTAssertNil(device.clockSourceIDs())
        XCTAssertNil(device.clockSourceName())
        XCTAssertNil(device.clockSourceNames())
        XCTAssertNil(device.clockSourceName(clockSourceID: 0))
        XCTAssertFalse(device.setClockSourceID(0))
    }

    func testLatency() throws {
        let device = try GetDevice()

        XCTAssertEqual(device.latency(direction: .playback), 0)
        XCTAssertEqual(device.latency(direction: .recording), 0)
    }

    func testSafetyOffset() throws {
        let device = try GetDevice()

        XCTAssertEqual(device.safetyOffset(direction: .playback), 0)
        XCTAssertEqual(device.safetyOffset(direction: .recording), 0)
    }

    func testHogMode() throws {
        let device = try GetDevice()

        XCTAssertEqual(device.hogModePID(), -1)
        XCTAssertTrue(device.setHogMode())
        XCTAssertEqual(device.hogModePID(), pid_t(ProcessInfo.processInfo.processIdentifier))
        XCTAssertTrue(device.unsetHogMode())
        XCTAssertEqual(device.hogModePID(), -1)
    }

    func testVolumeConversion() throws {
        let device = try GetDevice()

        XCTAssertEqual(device.scalarToDecibels(volume: 0, channel: 0, direction: .playback), -96.0)
        XCTAssertEqual(device.scalarToDecibels(volume: 1, channel: 0, direction: .playback), 6.0)

        XCTAssertEqual(device.decibelsToScalar(volume: -96.0, channel: 0, direction: .playback), 0)
        XCTAssertEqual(device.decibelsToScalar(volume: 6.0, channel: 0, direction: .playback), 1)
    }

    func testStreams() throws {
        let device = try GetDevice()

        XCTAssertNotNil(device.streams(direction: .playback))
        XCTAssertNotNil(device.streams(direction: .recording))
    }

    // MARK: - Private Functions

    private func GetDevice(file: StaticString = #file, line: UInt = #line) throws -> AudioDevice {
        return try XCTUnwrap(AudioDevice.lookup(by: "NullAudioDevice_UID"), "NullAudio driver is missing.", file: file, line: line)
    }

    private func ResetDefaultDevices() {
        defaultOutputDevice?.setAsDefaultOutputDevice()
        defaultInputDevice?.setAsDefaultInputDevice()
        defaultSystemOutputDevice?.setAsDefaultSystemDevice()
    }

    private func ResetDeviceState() throws {
        let device = try GetDevice()

        device.unsetHogMode()

        if device.nominalSampleRate() != 44100 {
            device.setNominalSampleRate(44100)
            sleep(1)
        }

        device.setPreferredChannelsForStereo(channels: StereoPair(left: 1, right: 2), direction: .playback)
        device.setMute(false, channel: 0, direction: .playback)
        device.setMute(false, channel: 0, direction: .recording)
        device.setVolume(0.5, channel: 0, direction: .playback)
        device.setVolume(0.5, channel: 0, direction: .recording)
        device.setVirtualMasterVolume(0.5, direction: .playback)
        device.setVirtualMasterVolume(0.5, direction: .recording)
    }
}
