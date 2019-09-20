//
//  AudioObjectPool.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 20/09/2019.
//  Copyright © 2019 9Labs. All rights reserved.
//

import Foundation

class AudioObjectPool {
    static var instancePool: NSMapTable<NSNumber, AudioObject> = NSMapTable.weakToWeakObjects()
}
