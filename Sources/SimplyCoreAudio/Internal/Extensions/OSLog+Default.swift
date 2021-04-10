//
//  OSLog+Default.swift
//
//  Created by Ruben Nine on 13/04/16.
//

import Foundation
import os.log

extension OSLog {
    fileprivate static let subsystem = Bundle.main.bundleIdentifier ?? "io.9labs.SimplyCoreAudio"

    /// Default logger.
    fileprivate static let `default` = OSLog(subsystem: subsystem, category: "Debug")

    /// Error logger.
    fileprivate static let error = OSLog(subsystem: subsystem, category: "Errors")
}

extension OSLog {
    /// Convenience for error messages with reference to what file the error came from
    static func error(fullname: String = #function,
                      file: String = #file,
                      line: Int = #line, _ items: Any?...) {
        let fileName = (file as NSString).lastPathComponent

        let content = (items.map {
            String(describing: $0 ?? "nil")
        }).joined(separator: " ")

        let message = "🚩 \(fileName):\(fullname):\(line):\(content)"
        os_log("%{public}@", log: .error, type: .error, message)
    }

    /// Convenience for debug messages with reference to what file the error came from
    static func debug(fullname: String = #function,
                      file: String = #file,
                      line: Int = #line,
                      _ items: Any?...) {
        let fileName = (file as NSString).lastPathComponent

        let content = (items.map {
            String(describing: $0 ?? "nil")
        }).joined(separator: " ")

        let message = "\(fileName):\(fullname):\(line):\(content)"
        os_log("%{public}@", log: .default, type: .default, message)
    }
}
