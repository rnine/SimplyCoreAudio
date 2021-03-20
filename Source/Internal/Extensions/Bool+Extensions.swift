//
//  Bool+Extensions.swift
//
//  Created by Ruben on 7/9/15.
//

import Foundation

extension Bool {
    init<T: BinaryInteger>(_ integer: T) {
        self.init(integer != 0)
    }
}
