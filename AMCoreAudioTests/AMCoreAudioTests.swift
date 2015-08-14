//
//  AMCoreAudioTests.swift
//  AMCoreAudioTests
//
//  Created by Ruben Nine on 14/08/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

import XCTest

class AMCoreAudioTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBoolWithIntegerInitializer() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        XCTAssertEqual(Bool(1), true)
        XCTAssertEqual(Bool(0), false)
    }
    
}
