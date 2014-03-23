//
//  AMCoreAudioHardware.h
//  AMCoreAudio
//
//  Created by Ruben Nine on 22/03/14.
//  Copyright (c) 2014 TroikaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@interface AMCoreAudioHardware : NSObject

/**
   A delegate conforming to the AMCoreAudioHardwareDelegate protocol.
 */
@property (weak, nonatomic) id<AMCoreAudioHardwareDelegate>delegate;

@end
