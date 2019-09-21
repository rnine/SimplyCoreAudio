import XCTest
@testable import AMCoreAudio

extension AudioStreamBasicDescription: Equatable {}

public func == (lhs: AudioStreamBasicDescription, rhs: AudioStreamBasicDescription) -> Bool {
    return
        lhs.mBitsPerChannel == rhs.mBitsPerChannel &&
        lhs.mBytesPerFrame == rhs.mBytesPerFrame &&
        lhs.mBytesPerPacket == rhs.mBytesPerPacket &&
        lhs.mChannelsPerFrame == rhs.mChannelsPerFrame &&
        lhs.mFormatFlags == rhs.mFormatFlags &&
        lhs.mFormatID == rhs.mFormatID &&
        lhs.mFramesPerPacket == rhs.mFramesPerPacket &&
        lhs.mReserved == rhs.mReserved
}

class AudioStreamTests: XCTestCase {
    func testProperties() throws {
        let device = try GetDevice()
        let outputStreams = try XCTUnwrap(device.streams(direction: .playback))
        let inputStreams = try XCTUnwrap(device.streams(direction: .recording))

        XCTAssertEqual(outputStreams.count, 1)
        XCTAssertEqual(inputStreams.count, 1)

        let outputStream = try XCTUnwrap(outputStreams.first)
        XCTAssertTrue(outputStream.active)
        XCTAssertNotNil(outputStream.startingChannel)
        XCTAssertEqual(outputStream.direction, .playback)
        XCTAssertEqual(outputStream.terminalType, .speaker)
        XCTAssertEqual(outputStream.latency, 0)
        XCTAssertNotNil(outputStream.availableVirtualFormats)
        XCTAssertNotNil(outputStream.availableVirtualFormatsMatchingCurrentNominalSampleRate())
        XCTAssertNotNil(outputStream.availableVirtualFormatsMatchingCurrentNominalSampleRate(true))
        XCTAssertNotNil(outputStream.availableVirtualFormatsMatchingCurrentNominalSampleRate(false))
        XCTAssertNotNil(outputStream.availablePhysicalFormats)
        XCTAssertNotNil(outputStream.availablePhysicalFormatsMatchingCurrentNominalSampleRate())
        XCTAssertNotNil(outputStream.availablePhysicalFormatsMatchingCurrentNominalSampleRate(true))
        XCTAssertNotNil(outputStream.availablePhysicalFormatsMatchingCurrentNominalSampleRate(false))

        let outVirtualFormat = try XCTUnwrap(outputStream.availableVirtualFormatsMatchingCurrentNominalSampleRate()?.first)
        outputStream.virtualFormat = nil
        XCTAssertEqual(outputStream.virtualFormat, outVirtualFormat)

        let outPhysicalFormat = try XCTUnwrap(outputStream.availablePhysicalFormatsMatchingCurrentNominalSampleRate()?.first)
        outputStream.physicalFormat = nil
        XCTAssertEqual(outputStream.physicalFormat, outPhysicalFormat)

        let inputStream = try XCTUnwrap(inputStreams.first)
        XCTAssertTrue(inputStream.active)
        XCTAssertNotNil(inputStream.startingChannel)
        XCTAssertEqual(inputStream.direction, .recording)
        XCTAssertEqual(inputStream.terminalType, .microphone)
        XCTAssertEqual(inputStream.latency, 0)
        XCTAssertNotNil(inputStream.availableVirtualFormats)
        XCTAssertNotNil(inputStream.availableVirtualFormatsMatchingCurrentNominalSampleRate())
        XCTAssertNotNil(inputStream.availableVirtualFormatsMatchingCurrentNominalSampleRate(true))
        XCTAssertNotNil(inputStream.availableVirtualFormatsMatchingCurrentNominalSampleRate(false))
        XCTAssertNotNil(inputStream.availablePhysicalFormats)
        XCTAssertNotNil(inputStream.availablePhysicalFormatsMatchingCurrentNominalSampleRate())
        XCTAssertNotNil(inputStream.availablePhysicalFormatsMatchingCurrentNominalSampleRate(true))
        XCTAssertNotNil(inputStream.availablePhysicalFormatsMatchingCurrentNominalSampleRate(false))

        let inVirtualFormat = try XCTUnwrap(inputStream.availableVirtualFormatsMatchingCurrentNominalSampleRate()?.first)
        inputStream.virtualFormat = nil
        XCTAssertEqual(inputStream.virtualFormat, inVirtualFormat)

        let inPhysicalFormat = try XCTUnwrap(inputStream.availablePhysicalFormatsMatchingCurrentNominalSampleRate()?.first)
        inputStream.physicalFormat = nil
        XCTAssertEqual(inputStream.physicalFormat, inPhysicalFormat)
    }

    // MARK: - Private Functions

    private func GetDevice(file: StaticString = #file, line: UInt = #line) throws -> AudioDevice {
        return try XCTUnwrap(AudioDevice.lookup(by: "NullAudioDevice_UID"), "NullAudio driver is missing.", file: file, line: line)
    }
}
