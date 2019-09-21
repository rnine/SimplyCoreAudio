import XCTest
@testable import AMCoreAudio

class BundleInfoTests: XCTestCase {
    func testProperties() {
        XCTAssertEqual(BundleInfo.name, "AMCoreAudio")
        XCTAssertNotNil(BundleInfo.version)
        XCTAssertNotNil(BundleInfo.buildNumber)
        XCTAssertNotNil(BundleInfo.buildDate)
        XCTAssertNotNil(BundleInfo.buildInfo())
    }
}
