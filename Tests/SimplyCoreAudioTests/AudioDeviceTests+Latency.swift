import XCTest

extension AudioDeviceTests {
    func testLatency() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.latency(scope: .output), 0)
        XCTAssertEqual(device.latency(scope: .input), 0)
    }

    func testSafetyOffset() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.safetyOffset(scope: .output), 0)
        XCTAssertEqual(device.safetyOffset(scope: .input), 0)
    }

    func testBufferFrameSize() throws {
        let device = try getNullDevice()

        // not sure why this is 512 by default?
        XCTAssertEqual(device.bufferFrameSize(scope: .output), 512)
        XCTAssertEqual(device.bufferFrameSize(scope: .input), 512)

        XCTAssertTrue(device.setBufferFrameSize(256, scope: .output))
        XCTAssertTrue(device.setBufferFrameSize(256, scope: .input))

        XCTAssertEqual(device.bufferFrameSize(scope: .output), 256)
        XCTAssertEqual(device.bufferFrameSize(scope: .input), 256)
    }
}
