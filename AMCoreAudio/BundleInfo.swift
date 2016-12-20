//
//  BundleInfo.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 29/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Foundation

/**
    This class provides information about this bundle such as: 
 
    - build date
    - name
    - version
    - builder number
 */
final public class BundleInfo {
    private init() {}

    private static let thisBundle = Bundle(for: BundleInfo.self)

    /// Returns this bundle's build date
    public static let buildDate: String? = thisBundle.infoDictionary?["BuildDate"] as? String

    /// Returns this bundle's name
    public static let name: String? = thisBundle.infoDictionary?["CFBundleName"] as? String

    /// Returns this bundle's version
    public static let version: String? = thisBundle.infoDictionary?["CFBundleShortVersionString"] as? String

    /// Returns this bundle's build number
    public static let buildNumber: String? = thisBundle.infoDictionary?["CFBundleVersion"] as? String

    /// Returns this bundle's build information
    public static func buildInfo() -> String? {

        guard let buildDate = buildDate, let name = name, let version = version, let buildNumber = buildNumber else {
            return nil
        }

        return "\(name) \(version) (build \(buildNumber)) built on \(buildDate)."
    }
}
