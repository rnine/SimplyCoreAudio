/*
   AMCoreAudioProtocols.h
   AMCoreAudio

   Created by Ruben Nine on 28/06/14.
   Copyright (c) 2014 TroikaLabs. All rights reserved.

   Licensed under the MIT license <http://opensource.org/licenses/MIT>

   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
   documentation files (the "Software"), to deal in the Software without restriction, including without limitation
   the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
   to permit persons to whom the Software is furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
   TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
   IN THE SOFTWARE.

 */

#import <Foundation/Foundation.h>
#import "AMCoreAudioTypes.h"

/**
   AMCoreAudioHardwareDelegate protocol
 */
@protocol AMCoreAudioHardwareDelegate <NSObject>

@optional

/**
   Called whenever the list of audio devices in the system changes.

   @note If you want to receive notifications when the list of owned audio devices on Aggregate Devices and Multi-Output devices changes, then try using AMCoreAudioDevice instead.
 */
- (void)hardwareDeviceListChanged:(id)sender;

/**
   Called whenever the system's default input device changes.
 */
- (void)hardwareDefaultInputDeviceChanged:(id)sender;

/**
   Called whenever the system's default output device changes.
 */
- (void)hardwareDefaultOutputDeviceChanged:(id)sender;

/**
   Called whenever the system's default device changes.

   @note This is the audio device used for alerts, sound effects, etc.
 */
- (void)hardwareDefaultSystemDeviceChanged:(id)sender;

@end

/**
   AMCoreAudioDeviceDelegate protocol
 */
@protocol AMCoreAudioDeviceDelegate <NSObject>

@optional

/**
   Called whenever the audio device's sample rate changes.
 */
- (void)audioDeviceNominalSampleRateDidChange:(id)sender;

/**
   Called whenever the audio device's list of nominal sample rates changes.

   @note This will typically happen on Aggregate Devices and Multi-Output devices when adding or removing other audio devices (either physical or virtual).
 */
- (void)audioDeviceAvailableNominalSampleRatesDidChange:(id)sender;

/**
   Called whenever the audio device's clock source changes for a given channel and direction.
 */
- (void)audioDeviceClockSourceDidChange:(id)sender
                             forChannel:(UInt32)channel
                           andDirection:(AMCoreAudioDirection)direction;

/**
   Called whenever the audio device's name changes.
 */
- (void)audioDeviceNameDidChange:(id)sender;

/**
   Called whenever the list of owned audio devices on this audio device changes.

   @note This will typically happen on Aggregate Devices and Multi-Output devices when adding or removing other audio devices (either physical or virtual).
 */
- (void)audioDeviceListDidChange:(id)sender;

/**
   Called whenever the audio device's volume for a given channel and direction changes.
 */
- (void)audioDeviceVolumeDidChange:(id)sender
                        forChannel:(UInt32)channel
                      andDirection:(AMCoreAudioDirection)direction;

/**
   Called whenever the audio device's mute state for a given channel and direction changes.
 */
- (void)audioDeviceMuteDidChange:(id)sender
                      forChannel:(UInt32)channel
                    andDirection:(AMCoreAudioDirection)direction;

@end
