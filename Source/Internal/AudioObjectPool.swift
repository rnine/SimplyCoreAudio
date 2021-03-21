//
//  AudioObjectPool.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import Foundation

class AudioObjectPool {
    // MARK: - Private Properties

    private let pool: NSMapTable<NSNumber, AudioObject> = NSMapTable.weakToWeakObjects()
    private lazy var queueLabel = Bundle(for: type(of: self)).bundleIdentifier!.appending(".audioObjectPool")
    private lazy var queue = DispatchQueue(label: queueLabel, qos: .default, attributes: .concurrent)

    // MARK: - Static Properties

    static let shared = AudioObjectPool()

    // MARK: - Lifecycle

    private init() {}
}

// MARK: - Internal Functions

extension AudioObjectPool {
    func get(_ id: UInt32) -> AudioObject? {
        queue.sync {
            pool.object(forKey: NSNumber(value: id))
        }
    }

    func set(_ audioObject: AudioObject, for id: UInt32) {
        queue.sync(flags: .barrier) {
            pool.setObject(audioObject, forKey: NSNumber(value: id))
        }
    }

    @discardableResult
    func remove(_ id: UInt32) -> Bool {
        queue.sync(flags: .barrier) {
            let key = NSNumber(value: id)

            guard pool.doesContain(key) else { return false }

            pool.removeObject(forKey: key)

            return true
        }
    }
}
