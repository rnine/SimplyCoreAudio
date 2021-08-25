#pragma once

#ifndef SimplyCoreAudio_h
#define SimplyCoreAudio_h

#include <Availability.h>
#import <AudioToolbox/AudioToolbox.h>

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
    #if __MAC_OS_X_VERSION_MAX_ALLOWED < 120000

        CF_ENUM(AudioObjectPropertySelector)
        {
            kAudioHardwareServiceDeviceProperty_VirtualMainVolume = 'vmvc',
            kAudioHardwareServiceDeviceProperty_VirtualMainBalance    = 'vmbc'
        };

        AudioObjectPropertyScope kAudioObjectPropertyElementMain = kAudioObjectPropertyElementMaster;

        #define kAudioAggregateDeviceMainSubDeviceKey "master"

    #endif /* __MAC_OS_X_VERSION_MAX_ALLOWED */
#endif

#endif
