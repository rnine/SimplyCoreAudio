//
//  AMCoreAudioDevice+PreferredDirections.m
//  AudioMate
//
//  Created by Ruben Nine on 17/01/14.
//  Copyright (c) 2014 Ruben Nine. All rights reserved.
//

#import "AMCoreAudioDevice+PreferredDirections.h"

@implementation AMCoreAudioDevice (PreferredDirections)

- (AMCoreAudioDirection)preferredDirectionForMasterVolume
{
    AMCoreAudioDirection direction;

    direction = kAMCoreAudioDeviceInvalidDirection;

    if (self.isInputOnlyDevice &&
        [self canSetMasterVolumeForDirection:kAMCoreAudioDeviceRecordDirection])
    {
        direction = kAMCoreAudioDeviceRecordDirection;
    }
    else if ([self canSetMasterVolumeForDirection:kAMCoreAudioDevicePlaybackDirection])
    {
        direction = kAMCoreAudioDevicePlaybackDirection;
    }

    return direction;
}

@end
