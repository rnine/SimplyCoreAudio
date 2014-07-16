//
//  AMCoreAudioDevice+PreferredDirections.h
//  AMCoreAudio
//
//  Created by Ruben Nine on 17/01/14.
//  Copyright (c) 2014 Ruben Nine. All rights reserved.
//

#import <AMCoreAudio/AMCoreAudio.h>

@interface AMCoreAudioDevice (PreferredDirections)

- (AMCoreAudioDirection)preferredDirectionForMasterVolume;

@end
