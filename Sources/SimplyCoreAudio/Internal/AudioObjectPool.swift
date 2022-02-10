//
//  AudioObjectPool.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import Foundation
import CoreAudio

class AudioObjectPool {
    // MARK: - Private Properties

    private var pool = [AudioObjectID: AudioObject]()
    private lazy var queueLabel = (Bundle.main.bundleIdentifier ?? "SimplyCoreAudio").appending(".audioObjectPool")
    private lazy var queue = DispatchQueue(label: queueLabel, qos: .default, attributes: .concurrent)

    // MARK: - Static Properties

    static let shared = AudioObjectPool()

    // MARK: - Lifecycle

    private init() {}
}

// MARK: - Internal Functions

extension AudioObjectPool {
    func get<O: AudioObject>(_ id: AudioObjectID) -> O? {
        queue.sync {
            pool[id] as? O
        }
    }

    func set<O: AudioObject>(_ audioObject: O, for id: AudioObjectID) {
        queue.sync(flags: .barrier) {
            pool[id] = audioObject
        }
    }

    func remove(_ id: AudioObjectID) {
        queue.async(flags: .barrier) { [weak self] in
            self?.pool.removeValue(forKey: id)
        }
    }
}
