//
//  XCTestCase+Wait.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import XCTest

extension XCTestCase {
    func wait(for interval: TimeInterval) {
        let delayExpectation = XCTestExpectation(description: "delayExpectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            delayExpectation.fulfill()
        }
        wait(for: [delayExpectation], timeout: interval + 1)
    }
}
