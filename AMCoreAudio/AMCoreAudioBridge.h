//
//  AMCoreAudioBridge.h
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/07/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

@import Foundation;
@import CoreAudio;

/**
    This bridging C function exists solely because sizeof(AudioValueTranslation) in Swift differs from
    the expected size in C (28 vs 32 respectively) and this causes AudioObjectGetPropertyData to fail
    with kAudioHardwareBadPropertySizeError.
 
    Naturally, the C implementation works just fine.
 */
OSStatus AMAudioHardwarePropertyDeviceForUID(NSString *uid, AudioObjectID *objectID);
