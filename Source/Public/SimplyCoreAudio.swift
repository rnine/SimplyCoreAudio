//
//  SimplyCoreAudio.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import Foundation

public final class SimplyCoreAudio {
    // MARK: - Private Properties

    private let hardware = AudioHardware()

    // MARK: - Lifecycle

    init() {
        hardware.enableDeviceMonitoring()
    }

    deinit {
        hardware.disableDeviceMonitoring()
    }
}
