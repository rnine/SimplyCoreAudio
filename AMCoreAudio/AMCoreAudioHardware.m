//
//  AMCoreAudioHardware.m
//  AMCoreAudio
//
//  Created by Ruben Nine on 22/03/14.
//  Copyright (c) 2014 TroikaLabs. All rights reserved.
//

#import "AMCoreAudioHardware.h"
#import <AudioToolbox/AudioServices.h>

@interface AMCoreAudioHardware ()
{
    BOOL _isRegisteredForNotifications;
}
@end

@implementation AMCoreAudioHardware

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        [self registerForNotifications];
    }

    return self;
}

- (void)dealloc
{
    [self unregisterForNotifications];
}

#pragma mark - Private methods

- (void)registerForNotifications
{
    AudioObjectPropertyAddress address = {
        kAudioObjectPropertySelectorWildcard,
        kAudioObjectPropertyScopeWildcard,
        kAudioObjectPropertyElementWildcard
    };

    OSStatus err = AudioObjectAddPropertyListener(kAudioObjectSystemObject, &address, TLD_AMCoreAudioHardwarePropertyListener, (__bridge void *)self);

    if (err)
    {
        DLog(@"error on AudioObjectAddPropertyListener %d\n", err);
    }

    _isRegisteredForNotifications = (noErr == err);
}

- (void)unregisterForNotifications
{
    if (_isRegisteredForNotifications)
    {
        AudioObjectPropertyAddress address = {
            kAudioObjectPropertySelectorWildcard,
            kAudioObjectPropertyScopeWildcard,
            kAudioObjectPropertyElementWildcard
        };

        OSStatus err = AudioObjectRemovePropertyListener(kAudioObjectSystemObject, &address, TLD_AMCoreAudioHardwarePropertyListener, (__bridge void *)self);

        if (err)
        {
            DLog(@"Error on AudioObjectRemovePropertyListener %d\n", err);
        }

        _isRegisteredForNotifications = !(noErr == err);
    }
}

#pragma mark - Static C functions

static OSStatus TLD_AMCoreAudioHardwarePropertyListener(AudioObjectID inObjectID,
                                                        UInt32 inNumberAddresses,
                                                        const AudioObjectPropertyAddress inAddresses[],
                                                        void *                           inClientData)
{
    AMCoreAudioHardware *self;

    self = (__bridge AMCoreAudioHardware *)(inClientData);

    switch (inAddresses->mSelector)
    {
        case kAudioObjectPropertyOwnedObjects:

            if (self.delegate)
            {
                [self.delegate hardwareDeviceListChanged:self];
            }

            break;

        case kAudioHardwarePropertyDefaultInputDevice:

            if (self.delegate)
            {
                [self.delegate hardwareDefaultInputDeviceChanged:self];
            }

            break;

        case kAudioHardwarePropertyDefaultOutputDevice:

            if (self.delegate)
            {
                [self.delegate hardwareDefaultOutputDeviceChanged:self];
            }

            break;

        case kAudioHardwarePropertyDefaultSystemOutputDevice:

            if (self.delegate)
            {
                [self.delegate hardwareDefaultSystemDeviceChanged:self];
            }

            break;

        default:

            return kAudioHardwareNoError;
    }

    return kAudioHardwareNoError;
}

@end
