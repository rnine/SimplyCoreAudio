//
//  AMCoreAudioDevice+Formatters.h
//  AMCoreAudio
//
//  Created by Ruben Nine on 12/20/12.
//  Copyright (c) 2012 Ruben Nine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/AudioHardware.h>
#import <AMCoreAudio/AMCoreAudio.h>

@interface AMCoreAudioDevice (Formatters)

+ (NSString *)formattedSampleRate:(Float64)sampleRate useShortFormat:(BOOL)useShortFormat;
+ (NSString *)formattedVolumeInDecibels:(Float32)theVolume;

- (NSString *)actualSampleRateFormattedWithShortFormat:(BOOL)useShortFormat;
- (NSString *)numberOfChannelsDescription;
- (NSString *)latencyDescription;

@end
