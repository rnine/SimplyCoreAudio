//
//  AudioObjectPool.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import Foundation

class AudioObjectPool {
    static var instancePool: NSMapTable<NSNumber, AudioObject> = NSMapTable.weakToWeakObjects()
}
