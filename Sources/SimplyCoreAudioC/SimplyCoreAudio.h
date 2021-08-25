#pragma once

#ifndef SimplyCoreAudio_h
#define SimplyCoreAudio_h

#include <Availability.h>
#import <AudioToolbox/AudioToolbox.h>

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
    #if __MAC_OS_X_VERSION_MAX_ALLOWED < 120000

        CF_ENUM(AudioObjectPropertySelector)
        {
            kAudioHardwareServiceDeviceProperty_VirtualMainVolume = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            kAudioHardwareServiceDeviceProperty_VirtualMainBalance = kAudioHardwareServiceDeviceProperty_VirtualMasterBalance
        };

        AudioObjectPropertyScope kAudioObjectPropertyElementMain = kAudioObjectPropertyElementMaster;

        #define kAudioAggregateDeviceMainSubDeviceKey "master"

    #endif
#endif

#endif
