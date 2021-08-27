/**
   These properties in AudioToolbox.h were renamed in macOS 12. In order to provide backwards compatibility for
   Xcode versions that are before v13, this creates duplicate properties of the future name. This file does
   nothing if you're working in Xcode 13+.
 */

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

static AudioObjectPropertyScope kAudioObjectPropertyElementMain = kAudioObjectPropertyElementMaster;

#endif
#endif /* __MAC_OS_X_VERSION_MAX_ALLOWED */

#ifndef kAudioAggregateDeviceMainSubDeviceKey
#define kAudioAggregateDeviceMainSubDeviceKey "master"
#endif

#endif /* SimplyCoreAudio_h */
