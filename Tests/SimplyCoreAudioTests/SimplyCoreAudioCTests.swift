
@testable import SimplyCoreAudioC
import XCTest

class SimplyCoreAudioCTests: XCTestCase {
    func testAPIChanges() {
        let vmvc = kAudioHardwareServiceDeviceProperty_VirtualMainVolume
        let vmbc = kAudioHardwareServiceDeviceProperty_VirtualMainBalance
        let elementMain = kAudioObjectPropertyElementMain
        let subDeviceKey = kAudioAggregateDeviceMainSubDeviceKey

        Swift.print(vmvc, vmbc, elementMain, subDeviceKey)

        XCTAssertEqual(vmvc, 1986885219)
        XCTAssertEqual(vmbc, 1986880099)
        XCTAssertEqual(elementMain, 0)
        XCTAssertEqual(subDeviceKey, "master")
    }
}
