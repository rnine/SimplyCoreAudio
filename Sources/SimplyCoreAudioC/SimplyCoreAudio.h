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

#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 120000
#define HAVE_AUDIO_OBJECT_PROPERTY_ELEMENT_MAIN 1
#endif

#ifndef HAVE_AUDIO_OBJECT_PROPERTY_ELEMENT_MAIN

CF_ENUM(AudioObjectPropertySelector)
{
	kAudioHardwareServiceDeviceProperty_VirtualMainVolume = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
	kAudioHardwareServiceDeviceProperty_VirtualMainBalance = kAudioHardwareServiceDeviceProperty_VirtualMasterBalance
};

static AudioObjectPropertyScope kAudioObjectPropertyElementMain = kAudioObjectPropertyElementMaster;

#endif /* HAVE_AUDIO_OBJECT_PROPERTY_ELEMENT_MAIN */

#ifndef kAudioAggregateDeviceMainSubDeviceKey
#define kAudioAggregateDeviceMainSubDeviceKey "master"
#endif

#endif /* SimplyCoreAudio_h */
