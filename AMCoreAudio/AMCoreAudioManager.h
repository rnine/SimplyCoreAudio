//
//  AMCoreAudioManager.h
//  AudioMate
//
//  Created by Ruben Nine on 10/07/14.
//  Copyright (c) 2014 Ruben Nine. All rights reserved.
//

@import Foundation;

@protocol AMCoreAudioManagerDelegate;

@class AMCoreAudioDevice;

/*!
   @class AMCoreAudioManager

   This class encapsulates most (if not all) of the functionality
   available in AMCoreAudioDevice and AMCoreAudioHardware but provides,
   a much easier and convenient interface.

   To receive audio device and audio hardware notifications,
   you may use the delegate pattern and conform to AMCoreAudioManagerDelegate.
 */
@interface AMCoreAudioManager : NSObject

/*!
   Returns a NSSet of all the the known devices in the system.

   @note This set is automatically maintained by AMCoreAudioManager
   (i.e., if the list of hardware devices changes, so will this NSSet.)
 */
@property (readonly, nonatomic, strong) NSSet *allKnownDevices;

/*!
   A delegate conforming to the AMCoreAudioManagerDelegate protocol.
 */
@property (nonatomic, weak) id<AMCoreAudioManagerDelegate> delegate;

/*!
   Returns the shared manager (singleton instance.)
 */
+ (instancetype)sharedManager;

/*!
   Sets the default input device.
 */
- (void)setDefaultInputDevice:(AMCoreAudioDevice *)audioDevice;

/*!
   Sets the default output device.
 */
- (void)setDefaultOutputDevice:(AMCoreAudioDevice *)audioDevice;

/*!
   Sets the default system output device.
 */
- (void)setDefaultSystemOutputDevice:(AMCoreAudioDevice *)audioDevice;

@end
