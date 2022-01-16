//
//  AudioObjectPool.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import Foundation

class AudioObjectPool {
    // MARK: - Private Properties

    private var pool = [UInt32: AudioObject]()
    private lazy var queueLabel = (Bundle.main.bundleIdentifier ?? "SimplyCoreAudio").appending(".audioObjectPool")
    private lazy var queue = DispatchQueue(label: queueLabel, qos: .default, attributes: .concurrent)

    // MARK: - Static Properties

    static let shared = AudioObjectPool()

    // MARK: - Lifecycle

    private init() {}
}

// MARK: - Internal Functions

extension AudioObjectPool {
    func get<O: AudioObject>(_ id: UInt32) -> O? {
        queue.sync {
            pool[id] as? O
        }
    }

    func set<O: AudioObject>(_ audioObject: O, for id: UInt32) {
        queue.sync(flags: .barrier) {
            pool[id] = audioObject
        }
    }

    @discardableResult
    func remove(_ id: UInt32) -> Bool {
        queue.sync(flags: .barrier) {
            pool.removeValue(forKey: id) != nil
        }
    }
}
