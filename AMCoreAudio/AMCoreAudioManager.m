//
//  AMCoreAudioManager.m
//  AudioMate
//
//  Created by Ruben Nine on 10/07/14.
//  Copyright (c) 2014 Ruben Nine. All rights reserved.
//

#import "AMCoreAudioManager.h"
#import "AMCoreAudioDevice.h"
#import "AMCoreAudioHardware.h"
@import CoreAudio.AudioHardware;

@interface AMCoreAudioManager () <AMCoreAudioDeviceDelegate,
                                  AMCoreAudioHardwareDelegate>

@property (nonatomic, strong) AMCoreAudioHardware *audioHardware;
@property (readwrite) NSSet *allKnownDevices;

@end

@implementation AMCoreAudioManager

#pragma mark - Singleton Pattern

+ (instancetype)sharedManager
{
    static AMCoreAudioManager *sharedManager = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedManager = [[super allocWithZone:NULL] init];
        sharedManager.allKnownDevices = [AMCoreAudioDevice allDevices];

        [sharedManager setup];
    });

    return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedManager];
}

#pragma mark - Public Methods

- (void)setDefaultInputDevice:(AMCoreAudioDevice *)audioDevice
{
    [audioDevice setAsDefaultDevice:kAudioHardwarePropertyDefaultInputDevice];
}

- (void)setDefaultOutputDevice:(AMCoreAudioDevice *)audioDevice
{
    [audioDevice setAsDefaultDevice:kAudioHardwarePropertyDefaultOutputDevice];
}

- (void)setDefaultSystemOutputDevice:(AMCoreAudioDevice *)audioDevice
{
    [audioDevice setAsDefaultDevice:kAudioHardwarePropertyDefaultSystemOutputDevice];
}

#pragma mark - AMCoreAudioDeviceDelegate Methods

- (void)hardwareDeviceListChanged:(id)sender
{
    NSSet *latestDeviceList;
    NSMutableSet *addedDevices;
    NSMutableSet *removedDevices;

    // Get the latest device list

    latestDeviceList = [AMCoreAudioDevice allDevices];

    // Do some basic arithmetic with mutable sets
    // to obtain added and removed devices

    addedDevices = [latestDeviceList mutableCopy];
    [addedDevices minusSet:self.allKnownDevices];

    removedDevices = [self.allKnownDevices mutableCopy];
    [removedDevices minusSet:latestDeviceList];

    // Update our allKnownDevices

    self.allKnownDevices = latestDeviceList;

    // Update delegates

    [self audioDeviceSetDelegatesFor:addedDevices
               andRemoveDelegatesFor:removedDevices];

    // And notify our delegate

    [self.delegate hardwareDeviceListChangedWithAddedDevices:[addedDevices copy]
                                           andRemovedDevices:[removedDevices copy]];
}

- (void)hardwareDefaultInputDeviceChanged:(id)sender
{
    AMCoreAudioDevice *audioDevice = [AMCoreAudioDevice defaultInputDevice];

    [self.delegate hardwareDefaultInputDeviceChangedTo:audioDevice];
}

- (void)hardwareDefaultOutputDeviceChanged:(id)sender
{
    AMCoreAudioDevice *audioDevice = [AMCoreAudioDevice defaultOutputDevice];

    [self.delegate hardwareDefaultOutputDeviceChangedTo:audioDevice];
}

- (void)hardwareDefaultSystemDeviceChanged:(id)sender
{
    AMCoreAudioDevice *audioDevice = [AMCoreAudioDevice systemOutputDevice];

    [self.delegate hardwareDefaultSystemDeviceChangedTo:audioDevice];
}

#pragma mark - AMCoreAudioDeviceDelegate Methods

- (void)audioDeviceNominalSampleRateDidChange:(id)sender
{
    [self.delegate audioDeviceNominalSampleRateDidChange:sender];
}

- (void)audioDeviceAvailableNominalSampleRatesDidChange:(id)sender
{
    [self.delegate audioDeviceAvailableNominalSampleRatesDidChange:sender];
}

- (void)audioDeviceClockSourceDidChange:(id)sender
                             forChannel:(UInt32)channel
                           andDirection:(AMCoreAudioDirection)direction
{
    [self.delegate audioDeviceClockSourceDidChange:sender
                                        forChannel:channel
                                      andDirection:direction];
}

- (void)audioDeviceNameDidChange:(id)sender
{
    [self.delegate audioDeviceNameDidChange:sender];
}

- (void)audioDeviceListDidChange:(id)sender
{
    [self.delegate audioDeviceListDidChange:sender];
}

- (void)audioDeviceVolumeDidChange:(id)sender
                        forChannel:(UInt32)channel
                      andDirection:(AMCoreAudioDirection)direction
{
    [self.delegate audioDeviceVolumeDidChange:sender
                                   forChannel:channel
                                 andDirection:direction];
}

- (void)audioDeviceMuteDidChange:(id)sender
                      forChannel:(UInt32)channel
                    andDirection:(AMCoreAudioDirection)direction
{
    [self.delegate audioDeviceMuteDidChange:sender
                                 forChannel:channel
                               andDirection:direction];
}

- (void)audioDeviceIsAliveDidChange:(id)sender
{
    [self.delegate audioDeviceIsAliveDidChange:sender];
}

- (void)audioDeviceIsRunningDidChange:(id)sender
{
    [self.delegate audioDeviceIsRunningDidChange:sender];
}


#pragma mark - Private

- (void)setup
{
    // Update delegates

    [self audioDeviceSetDelegatesFor:self.allKnownDevices
               andRemoveDelegatesFor:nil];

    // Initialize our AMCoreAudioHardware object and set its delegate
    // to self, so we can start receiving hardware-related notifications

    self.audioHardware = [AMCoreAudioHardware new];
    self.audioHardware.delegate = self;
}

- (void)audioDeviceSetDelegatesFor:(id <NSFastEnumeration>)addedDevices
             andRemoveDelegatesFor:(id <NSFastEnumeration>)removedDevices
{
    for (AMCoreAudioDevice *device in addedDevices)
    {
        device.delegate = self;

        DLog(@"Set delegate for %@", device.deviceName);
    }

    for (AMCoreAudioDevice *device in removedDevices)
    {
        device.delegate = nil;

        DLog(@"Removed delegate for %@", device.cachedDeviceName);
    }
}

@end
