//
//  AudioObjectPool.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import Foundation

class AudioObjectPool {
    // MARK: - Private Properties

    private let pool: NSMapTable<NSNumber, AudioObject> = NSMapTable.weakToWeakObjects()

    // MARK: - Static Properties

    static let shared = AudioObjectPool()

    // MARK: - Lifecycle

    private init() {}
}

// MARK: - Internal Functions

extension AudioObjectPool {
    func get(_ id: UInt32) -> AudioObject? {
        pool.object(forKey: NSNumber(value: id))
    }

    func set(_ audioObject: AudioObject, for id: UInt32) {
        pool.setObject(audioObject, forKey: NSNumber(value: id))
    }

    @discardableResult
    func remove(_ id: UInt32) -> Bool {
        let key = NSNumber(value: id)

        if pool.doesContain(key) {
            pool.removeObject(forKey: key)
            return true
        } else {
            return false
        }
    }
}
