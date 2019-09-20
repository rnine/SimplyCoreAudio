//
//  Utils.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import CoreAudio.AudioHardwareBase
import Foundation

private let logDateFormatter: DateFormatter = {
    $0.locale = NSLocale.current
    $0.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

    return $0
}(DateFormatter())

func log(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
    let filename = file.components(separatedBy: "/").last ?? file

    print("\(logDateFormatter.string(from: Date())) [AMCoreAudio] [\(filename):\(line)] \(function) > \(message)")
}

func scope(direction: Direction) -> AudioObjectPropertyScope {
    return direction == .playback ? kAudioObjectPropertyScopeOutput : kAudioObjectPropertyScopeInput
}

func direction(to scope: AudioObjectPropertyScope) -> Direction? {
    switch scope {
    case kAudioObjectPropertyScopeOutput:
        return .playback
    case kAudioObjectPropertyScopeInput:
        return .recording
    default:
        return nil
    }
}
