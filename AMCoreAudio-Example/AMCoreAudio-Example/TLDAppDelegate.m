//
//  TLDAppDelegate.m
//  AMCoreAudio-Example
//
//  Created by Ruben Nine on 24/03/14.
//  Copyright (c) 2014 Ruben Nine. All rights reserved.
//

#import "TLDAppDelegate.h"
#import <AMCoreAudio/AMCoreAudio.h>

@interface TLDAppDelegate () <AMCoreAudioManagerDelegate>

@property (nonatomic, strong) AMCoreAudioManager *audioDeviceManager;

@end

@implementation TLDAppDelegate

#pragma mark - Accessors

-(AMCoreAudioManager *)audioDeviceManager {
    if (!_audioDeviceManager) {
        _audioDeviceManager = [AMCoreAudioManager sharedManager];
    }

    return _audioDeviceManager;
}

#pragma mark - NSApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Set AMCoreAudioManager delegate
    self.audioDeviceManager.delegate = self;

    NSLog(@"All known devices: %@", self.audioDeviceManager.allKnownDevices);
}

#pragma mark - AMCoreAudioManagerDelegate Methods

-(void)hardwareDeviceListChangedWithAddedDevices:(NSSet *)addedDevices andRemovedDevices:(NSSet *)removedDevices
{
    NSLog(@"Devices added: %@", addedDevices);
    NSLog(@"Devices removed: %@", removedDevices);
}

-(void)hardwareDefaultInputDeviceChangedTo:(AMCoreAudioDevice *)audioDevice
{
    NSLog(@"Default input device changed to %@", audioDevice);
}

-(void)hardwareDefaultOutputDeviceChangedTo:(AMCoreAudioDevice *)audioDevice
{
    NSLog(@"Default output device changed to %@", audioDevice);
}

-(void)hardwareDefaultSystemDeviceChangedTo:(AMCoreAudioDevice *)audioDevice
{
    NSLog(@"System output device changed to %@", audioDevice);
}

-(void)audioDeviceListDidChange:(AMCoreAudioDevice *)audioDevice {
    NSLog(@"%@ owned devices list changed", audioDevice);
}

-(void)audioDeviceNominalSampleRateDidChange:(AMCoreAudioDevice *)audioDevice
{
    NSLog(@"%@ sample rate changed to %f", audioDevice, audioDevice.nominalSampleRate);
}

-(void)audioDeviceVolumeDidChange:(AMCoreAudioDevice *)audioDevice forChannel:(UInt32)channel andDirection:(AMCoreAudioDirection)direction
{
    Float32 newVolume = [audioDevice volumeInDecibelsForChannel:channel
                                                   andDirection:direction];

    NSLog(@"%@ volume for channel %d and direction %ld changed to %.2fdbFS", audioDevice, channel, direction, newVolume);
}

-(void)audioDeviceMuteDidChange:(AMCoreAudioDevice *)audioDevice forChannel:(UInt32)channel andDirection:(AMCoreAudioDirection)direction
{
    BOOL isMuted = [audioDevice isChannelMuted:channel andDirection:direction];

    NSLog(@"%@ mute for channel %d and direction %ld changed to %d", audioDevice, channel, direction, isMuted);
}

-(void)audioDeviceClockSourceDidChange:(AMCoreAudioDevice *)audioDevice forChannel:(UInt32)channel andDirection:(AMCoreAudioDirection)direction
{
    NSString *clockSourceName = [audioDevice clockSourceForChannel:channel
                                                      andDirection:direction];

    NSLog(@"%@ clock source changed to %@", audioDevice, clockSourceName);
}

-(void)audioDeviceNameDidChange:(AMCoreAudioDevice *)audioDevice
{
    NSLog(@"%@ name changed to %@", audioDevice.deviceUID, audioDevice);
}

-(void)audioDeviceAvailableNominalSampleRatesDidChange:(AMCoreAudioDevice *)audioDevice
{
    NSLog(@"%@ nominal sample rates changed to %@", audioDevice, [audioDevice nominalSampleRates]);
}

-(void)audioDeviceIsAliveDidChange:(AMCoreAudioDevice *)audioDevice
{
    NSLog(@"%@ 'is alive' changed to %@", audioDevice, @([audioDevice isAlive]));
}

- (void)audioDeviceIsRunningDidChange:(AMCoreAudioDevice *)audioDevice
{
    NSLog(@"%@ 'is running' changed to %@", audioDevice, @([audioDevice isRunning]));
}

- (void)audioDeviceIsRunningSomewhereDidChange:(AMCoreAudioDevice *)audioDevice
{
    NSLog(@"%@ 'is running somewhere' changed to %@", audioDevice, @([audioDevice isRunningSomewhere]));
}

@end
