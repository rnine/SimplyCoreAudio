//
//  OSLog+Default.swift
//
//  Created by Ruben Nine on 13/04/16.
//

import Foundation
import os.log

extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "SimplyCoreAudio"

    /// Default logger.
    static let `default` = OSLog(subsystem: subsystem, category: "default")
}
