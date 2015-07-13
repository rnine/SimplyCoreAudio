//
//  AMCoreAudioBridge.m
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/07/15.
//  Copyright © 2015 9Labs. All rights reserved.
//

#import "AMCoreAudioBridge.h"

OSStatus AMAudioHardwarePropertyDeviceForUID(NSString *uid, AudioObjectID *objectID) {
    OSStatus theStatus;
    UInt32 theSize;
    AudioValueTranslation theTranslation;

    theTranslation.mInputData = &uid;
    theTranslation.mInputDataSize = sizeof(CFStringRef);
    theTranslation.mOutputData = objectID;
    theTranslation.mOutputDataSize = sizeof(AudioObjectID);
    theSize = sizeof(AudioValueTranslation);

    AudioObjectPropertyAddress address = {
        kAudioHardwarePropertyDeviceForUID,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    theStatus = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theTranslation);

    return theStatus;
}
