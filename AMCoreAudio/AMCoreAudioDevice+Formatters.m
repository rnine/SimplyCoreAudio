//
//  AMCoreAudioDevice+Formatters.m
//  AMCoreAudio
//
//  Created by Ruben Nine on 12/20/12.
//  Copyright (c) 2012 Ruben Nine. All rights reserved.
//

#import "AMCoreAudioDevice+Formatters.h"

@implementation AMCoreAudioDevice (Formatters)

+ (NSString *)formattedSampleRate:(Float64)sampleRate
                   useShortFormat:(BOOL)useShortFormat
{
    NSString *formattedString;

    if (useShortFormat)
    {
        formattedString = [NSString stringWithFormat:@"%.1f kHz", sampleRate * 0.001];
    }
    else
    {
        formattedString = [NSString stringWithFormat:@"%.3f kHz", sampleRate * 0.001];
    }

    return formattedString;
}

+ (NSString *)formattedVolumeInDecibels:(Float32)theVolume
{
    return [NSString stringWithFormat:@"%.1fdB", theVolume];
}

- (NSString *)actualSampleRateFormattedWithShortFormat:(BOOL)useShortFormat
{
    NSString *formattedString = [self.class formattedSampleRate:self.actualSampleRate
                                                 useShortFormat:useShortFormat];

    return formattedString;
}

- (NSString *)numberOfChannelsDescription
{
    UInt32 inputChannels;
    UInt32 outputChannels;

    inputChannels = [self channelsForDirection:kAMCoreAudioDeviceRecordDirection];
    outputChannels = [self channelsForDirection:kAMCoreAudioDevicePlaybackDirection];

    NSString *formattedString = [NSString stringWithFormat:NSLocalizedString(@"%d in/ %d out", nil),
                                 inputChannels,
                                 outputChannels];

    return formattedString;
}

- (NSString *)latencyDescription
{
    NSMutableString *formattedString;
    UInt32 inLatency;
    UInt32 outLatency;
    UInt32 inSafetyOffsetLatency;
    UInt32 outSafetyOffsetLatency;
    UInt32 totalInLatency;
    UInt32 totalOutLatency;

    formattedString = [NSMutableString string];

    inLatency = [self deviceLatencyFramesForDirection:kAMCoreAudioDeviceRecordDirection];
    outLatency = [self deviceLatencyFramesForDirection:kAMCoreAudioDevicePlaybackDirection];
    inSafetyOffsetLatency = [self deviceSafetyOffsetFramesForDirection:kAMCoreAudioDeviceRecordDirection];
    outSafetyOffsetLatency = [self deviceSafetyOffsetFramesForDirection:kAMCoreAudioDevicePlaybackDirection];

    totalInLatency = inLatency + inSafetyOffsetLatency;
    totalOutLatency = outLatency + outSafetyOffsetLatency;

    if (totalInLatency > 0)
    {
        [formattedString appendFormat:NSLocalizedString(@"%.1fms in", nil),
         (double)totalInLatency / self.nominalSampleRate * 1000];
    }

    if (totalOutLatency > 0)
    {
        if (formattedString.length > 0)
        {
            [formattedString appendString:NSLocalizedString(@"/ ", nil)];
        }

        [formattedString appendFormat:NSLocalizedString(@"%.1fms out", nil),
         (double)totalOutLatency / self.nominalSampleRate * 1000];
    }

    return [formattedString copy];
}

@end
