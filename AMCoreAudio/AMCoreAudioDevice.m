/*
   AMCoreAudioDevice.m
   AMCoreAudio

   Created by Ruben Nine on 7/29/13.
   Copyright (c) 2013, 2014 TroikaLabs. All rights reserved.

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

#import "AMCoreAudioTypes.h"
#import "AMCoreAudioDevice.h"
#import <AudioToolbox/AudioServices.h>

NSString *const AMCoreAudioDefaultClockSourceName = @"Default";

@interface AMCoreAudioDevice ()

@property (nonatomic, assign) BOOL isRegisteredForNotifications;
@property (readwrite, nonatomic, retain) NSArray *nominalSampleRates;

@end

@implementation AMCoreAudioDevice

#pragma mark - Class Methods

+ (NSSet *)allDeviceIDs
{
    NSMutableSet *theSet;
    UInt32 theSize;
    OSStatus theStatus;
    NSUInteger numDevices;
    NSUInteger x;
    AudioObjectID *deviceList;

    AudioObjectPropertyAddress address = {
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    theStatus = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize);

    if (noErr != theStatus)
    {
        return nil;
    }

    numDevices = theSize / sizeof(AudioObjectID);
    deviceList = (AudioObjectID *)malloc(theSize);

    if (!deviceList)
    {
        return nil;
    }

    theStatus = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           deviceList);

    if (noErr != theStatus)
    {
        free(deviceList);

        return nil;
    }

    theSet = [[NSMutableSet alloc] initWithCapacity:numDevices];

    for (x = 0; x < numDevices; x++)
    {
        [theSet addObject:@(deviceList[x])];
    }

    free(deviceList);

    return [theSet copy];
}

+ (NSSet *)allDevices
{
    NSSet *deviceIDs;
    NSMutableSet *devices;
    AMCoreAudioDevice *device;

    deviceIDs = [self allDeviceIDs];
    devices = [[NSMutableSet alloc] initWithCapacity:deviceIDs.count];

    for (id deviceID in deviceIDs)
    {
        device = [[self alloc] initWithDeviceID:[deviceID intValue]];

        [devices addObject:device];
    }

    return [devices copy];
}

+ (NSSet *)allInputDevices
{
    NSMutableSet *devices;

    devices = [NSMutableSet set];

    for (id device in [self allDevices])
    {
        if ([device channelsForDirection:kAMCoreAudioDeviceRecordDirection] > 0)
        {
            [devices addObject:device];
        }
    }

    return [devices copy];
}

+ (NSSet *)allOutputDevices
{
    NSMutableSet *devices;

    devices = [NSMutableSet set];

    for (id device in [self allDevices])
    {
        if ([device channelsForDirection:kAMCoreAudioDevicePlaybackDirection] > 0)
        {
            [devices addObject:device];
        }
    }

    return [devices copy];
}

+ (AMCoreAudioDevice *)deviceWithID:(AudioObjectID)theID
{
    return [[self alloc] initWithDeviceID:theID];
}

+ (AMCoreAudioDevice *)deviceWithUID:(NSString *)theUID
{
    OSStatus theStatus;
    UInt32 theSize;
    AudioValueTranslation theTranslation;
    AudioObjectID theID;
    AMCoreAudioDevice *audioDevice;

    theTranslation.mInputData = &theUID;
    theTranslation.mInputDataSize = sizeof(CFStringRef);
    theTranslation.mOutputData = &theID;
    theTranslation.mOutputDataSize = sizeof(AudioObjectID);
    theSize = sizeof(AudioValueTranslation);

    AudioObjectPropertyAddress address = {
        kAudioHardwarePropertyDeviceForUID,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    theStatus = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theTranslation);

    if (noErr == theStatus)
    {
        audioDevice = [self deviceWithID:theID];
    }

    if ([theUID isEqual:audioDevice.deviceUID])
    {
        return audioDevice;
    }

    return nil;
}

+ (AMCoreAudioDevice *)_defaultDevice:(AudioObjectPropertySelector)whichDevice
{
    OSStatus theStatus;
    UInt32 theSize;
    AudioObjectID theID;

    AudioObjectPropertyAddress address = {
        whichDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(AudioObjectID);

    theStatus = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theID);

    if (noErr == theStatus)
    {
        return [self deviceWithID:theID];
    }

    return nil;
}

+ (AMCoreAudioDevice *)defaultInputDevice
{
    return [self _defaultDevice:kAudioHardwarePropertyDefaultInputDevice];
}

+ (AMCoreAudioDevice *)defaultOutputDevice
{
    return [self _defaultDevice:kAudioHardwarePropertyDefaultOutputDevice];
}

+ (AMCoreAudioDevice *)systemOutputDevice
{
    return [self _defaultDevice:kAudioHardwarePropertyDefaultSystemOutputDevice];
}

#pragma mark - Instance Methods

- (BOOL)setAsDefaultDevice:(AudioObjectPropertySelector)defaultDeviceType
{
    OSStatus theStatus;
    UInt32 theSize;
    AudioObjectID deviceID;

    AudioObjectPropertyAddress address = {
        defaultDeviceType,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(AudioObjectID);
    deviceID = self.deviceID;

    theStatus = AudioObjectSetPropertyData(kAudioObjectSystemObject,
                                           &address,
                                           0,
                                           NULL,
                                           theSize,
                                           &deviceID);

    return noErr == theStatus;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Must use initWithDeviceID: instead."
                                 userInfo:nil];
}

- (AMCoreAudioDevice *)initWithDeviceID:(AudioObjectID)AudioObjectID
{
    self = [super init];

    if (self)
    {
        self.deviceID = AudioObjectID;
        _cachedDeviceName = TLD_DeviceNameForID(self.deviceID);
    }

    return self;
}

- (void)setDelegate:(id <AMCoreAudioDeviceDelegate> )delegate
{
    if (delegate)
    {
        [self registerForNotifications];
    }
    else
    {
        [self unregisterForNotifications];
    }

    _delegate = delegate;
}

- (void)dealloc
{
    self.delegate = nil;
}

- (AMCoreAudioDevice *)clone
{
    return [self.class deviceWithID:self.deviceID];
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
    {
        return YES;
    }

    if (!other || ![other isKindOfClass:[self class]])
    {
        return NO;
    }

    return [self isEqualToAudioDevice:other];
}

- (BOOL)isEqualToAudioDevice:(AMCoreAudioDevice *)audioDevice
{
    return audioDevice.hash == self.hash;
}

- (NSUInteger)hash
{
    return self.deviceID;
}

- (NSString *)description
{
    NSString *deviceName;

    deviceName = self.deviceName;

    if (!deviceName)
    {
        deviceName = self.cachedDeviceName;
    }

    return [NSString stringWithFormat:@"<%@: %p id %d> %@",
            self.className,
            self,
            self.deviceID,
            deviceName];
}

#pragma mark - General Device Information Methods

- (NSString *)deviceName
{
    NSString *aDeviceName;

    aDeviceName = TLD_DeviceNameForID(self.deviceID);

    if (aDeviceName)
    {
        _cachedDeviceName = aDeviceName;
    }

    return aDeviceName;
}

- (NSString *)deviceUID
{
    OSStatus theStatus;
    NSString *theString;
    UInt32 theSize;

    theSize = sizeof(CFStringRef);

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyDeviceUID,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theString);

    if (noErr != theStatus || !theString)
    {
        return nil;
    }

    return theString;
}

- (NSString *)deviceManufacturer
{
    OSStatus theStatus;
    NSString *theString;
    UInt32 theSize;

    theSize = sizeof(CFStringRef);

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyDeviceManufacturerCFString,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theString);

    if (noErr != theStatus || !theString)
    {
        return nil;
    }

    return theString;
}

- (NSURL *)deviceIconURL
{
    OSStatus theStatus;
    NSURL *theURL;
    UInt32 theSize;

    theSize = sizeof(CFURLRef);

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyIcon,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theURL);

    if (noErr != theStatus || !theURL)
    {
        return nil;
    }

    return theURL;
}

- (NSString *)deviceConfigurationApplication
{
    OSStatus theStatus;
    NSString *theString;
    UInt32 theSize;

    theSize = sizeof(CFStringRef);

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyConfigurationApplication,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theString);

    if (noErr != theStatus || !theString)
    {
        return nil;
    }

    return theString;
}

- (NSString *)nameForChannel:(UInt32)theChannel
                andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    CFStringRef theCFString;
    NSString *rv;
    UInt32 theSize;

    AudioObjectPropertyAddress address = {
        kAudioObjectPropertyElementName,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    theSize = sizeof(CFStringRef);
    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theCFString);

    if (theStatus != 0 || theCFString == NULL)
    {
        return nil;
    }

    rv = CFBridgingRelease(theCFString);

    return rv;
}

#pragma mark - Input/Output Layout Methods

- (NSArray *)channelsByStreamForDirection:(AMCoreAudioDirection)theDirection
{
    AudioBufferList *theList;
    NSMutableArray *rv;
    OSStatus theStatus;
    UInt32 theSize;
    UInt32 x;
    BOOL hasProperty;

    rv = [NSMutableArray arrayWithCapacity:1];

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyStreamConfiguration,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        kAudioObjectPropertyElementMaster
    };

    hasProperty = AudioObjectHasProperty(self.deviceID,
                                         &address);

    if (!hasProperty)
    {
        return nil;
    }

    theStatus = AudioObjectGetPropertyDataSize(self.deviceID,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize);

    if (noErr != theStatus)
    {
        return nil;
    }

    theList = (AudioBufferList *)malloc(theSize);

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           theList);

    if (noErr != theStatus)
    {
        free(theList);

        return nil;
    }

    for (x = 0; x < theList->mNumberBuffers; x++)
    {
        [rv addObject:@(theList->mBuffers[x].mNumberChannels)];
    }

    free(theList);

    return [rv copy];
}

- (UInt32)channelsForDirection:(AMCoreAudioDirection)theDirection
{
    UInt32 rv = 0;

    for (id numberOfChannels in[self channelsByStreamForDirection:theDirection])
    {
        rv += [numberOfChannels unsignedLongValue];
    }

    return rv;
}

- (BOOL)isInputOnlyDevice
{
    NSUInteger playbackChannels;
    NSUInteger recordingChannels;

    playbackChannels = [self channelsForDirection:kAMCoreAudioDevicePlaybackDirection];
    recordingChannels = [self channelsForDirection:kAMCoreAudioDeviceRecordDirection];

    return (recordingChannels > 0) && (playbackChannels == 0);
}

- (BOOL)isOutputOnlyDevice
{
    NSUInteger playbackChannels;
    NSUInteger recordingChannels;

    playbackChannels = [self channelsForDirection:kAMCoreAudioDevicePlaybackDirection];
    recordingChannels = [self channelsForDirection:kAMCoreAudioDeviceRecordDirection];

    return (playbackChannels > 0) && (recordingChannels == 0);
}

#pragma mark - Individual Channel Methods

- (AMCoreAudioVolumeInfo)volumeInfoForChannel:(UInt32)theChannel
                                 andDirection:(AMCoreAudioDirection)theDirection
{
    AMCoreAudioVolumeInfo rv;
    OSStatus theStatus;
    UInt32 theSize;
    UInt32 tmpBool32;
    BOOL hasProperty;

    rv.hasVolume = false;
    rv.canSetVolume = false;
    rv.canMute = false;
    rv.canPlayThru = false;
    rv.theVolume = 0.0;
    rv.isMuted = false;
    rv.isPlayThruSet = false;

    // obtain volume info

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyVolumeScalar,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    hasProperty = AudioObjectHasProperty(self.deviceID,
                                         &address);

    if (!hasProperty)
    {
        return rv;
    }

    theStatus = AudioObjectGetPropertyDataSize(self.deviceID,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize);

    if (theStatus != noErr)
    {
        return rv;
    }

    theStatus = AudioObjectIsPropertySettable(self.deviceID,
                                              &address,
                                              &rv.canSetVolume);

    if (noErr == theStatus)
    {
        rv.hasVolume = true;
        theStatus = AudioObjectGetPropertyData(self.deviceID,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize,
                                               &rv.theVolume);

        if (noErr != theStatus)
        {
            rv.theVolume = 0.0;
        }
    }


    // obtain mute info

    address.mSelector = kAudioDevicePropertyMute;

    hasProperty = AudioObjectHasProperty(self.deviceID,
                                         &address);

    if (!hasProperty)
    {
        return rv;
    }

    theStatus = AudioObjectGetPropertyDataSize(self.deviceID,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize);

    if (theStatus != noErr)
    {
        return rv;
    }

    theStatus = AudioObjectIsPropertySettable(self.deviceID,
                                              &address,
                                              &rv.canMute);

    if (noErr == theStatus)
    {
        theStatus = AudioObjectGetPropertyData(self.deviceID,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize,
                                               &tmpBool32);

        if (noErr == theStatus)
        {
            rv.isMuted = tmpBool32;
        }
    }


    // obtain play thru info

    address.mSelector = kAudioDevicePropertyPlayThru;

    hasProperty = AudioObjectHasProperty(self.deviceID,
                                         &address);

    if (!hasProperty)
    {
        return rv;
    }

    theStatus = AudioObjectGetPropertyDataSize(self.deviceID,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize);

    if (theStatus != noErr)
    {
        return rv;
    }

    theStatus = AudioObjectIsPropertySettable(self.deviceID,
                                              &address,
                                              &rv.canPlayThru);

    if (noErr == theStatus)
    {
        theStatus = AudioObjectGetPropertyData(self.deviceID,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize,
                                               &tmpBool32);

        if (noErr == theStatus)
        {
            rv.isPlayThruSet = tmpBool32;
        }
    }

    return rv;
}

- (Float32)volumeForChannel:(UInt32)theChannel
               andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    Float32 theVolumeScalar;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyVolumeScalar,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    theSize = sizeof(Float32);

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theVolumeScalar);

    if (noErr == theStatus)
    {
        return theVolumeScalar;
    }
    else
    {
        return 0.0;
    }
}

- (Float32)volumeInDecibelsForChannel:(UInt32)theChannel
                         andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    Float32 theVolumeDecibels;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyVolumeDecibels,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    theSize = sizeof(Float32);

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theVolumeDecibels);

    if (noErr == theStatus)
    {
        return theVolumeDecibels;
    }
    else
    {
        return 0.0;
    }
}

- (BOOL)setVolume:(Float32)theVolume
       forChannel:(UInt32)theChannel
     andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyVolumeScalar,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    theSize = sizeof(Float32);

    theStatus = AudioObjectSetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           theSize,
                                           &theVolume);

    return noErr == theStatus;
}

- (BOOL) setMute:(BOOL)isMuted
      forChannel:(UInt32)theChannel
    andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    UInt32 valMute;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyMute,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    valMute = (UInt32)isMuted;
    theSize = sizeof(UInt32);

    theStatus = AudioObjectSetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           theSize,
                                           &valMute);

    return noErr == theStatus;
}

- (BOOL)isChannelMuted:(UInt32)theChannel
          andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    UInt32 valMute;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyMute,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    theSize = sizeof(UInt32);

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &valMute);

    if (noErr == theStatus)
    {
        return (BOOL)valMute;
    }

    return NO;
}

- (BOOL)canMuteForChannel:(UInt32)theChannel
             andDirection:(AMCoreAudioDirection)theDirection
{
    AMCoreAudioVolumeInfo vi;

    vi = [self volumeInfoForChannel:theChannel
                       andDirection:theDirection];

    return vi.canMute;
}

- (BOOL)canMuteMasterVolumeForDirection:(AMCoreAudioDirection)theDirection
{
    NSInteger muteCount;
    NSArray *preferredStereoChannels;

    if ([self canMuteForChannel:kAudioObjectPropertyElementMaster
                   andDirection:theDirection])
    {
        return YES;
    }

    preferredStereoChannels = [self preferredStereoChannelsForDirection:theDirection];
    muteCount = 0;

    if (preferredStereoChannels.count == 0)
    {
        return NO;
    }

    for (NSNumber *channel in preferredStereoChannels)
    {
        if ([self canMuteForChannel:channel.intValue
                       andDirection:theDirection])
        {
            muteCount++;
        }
    }

    return muteCount == preferredStereoChannels.count;
}

- (BOOL)canSetVolumeForChannel:(UInt32)theChannel
                  andDirection:(AMCoreAudioDirection)theDirection
{
    AMCoreAudioVolumeInfo vi;

    vi = [self volumeInfoForChannel:theChannel
                       andDirection:theDirection];

    return vi.canSetVolume;
}

- (NSArray *)preferredStereoChannelsForDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    UInt32 preferredChannels[2];
    NSArray *theChannels;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyPreferredChannelsForStereo,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(preferredChannels);

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &preferredChannels);

    if (noErr == theStatus)
    {
        theChannels = @[
            @(preferredChannels[0]),
            @(preferredChannels[1])
                      ];

        return theChannels;
    }
    else
    {
        return @[];
    }
}

#pragma mark - Master Volume Methods

- (BOOL)canSetMasterVolumeForDirection:(AMCoreAudioDirection)theDirection
{
    NSInteger settableChannelsCount;
    NSArray *preferredStereoChannels;

    if ([self canSetVolumeForChannel:kAudioObjectPropertyElementMaster
                        andDirection:theDirection])
    {
        return YES;
    }

    preferredStereoChannels = [self preferredStereoChannelsForDirection:theDirection];
    settableChannelsCount = 0;

    if (preferredStereoChannels.count == 0)
    {
        return NO;
    }

    for (NSNumber *channel in preferredStereoChannels)
    {
        if ([self canSetVolumeForChannel:channel.intValue
                            andDirection:theDirection])
        {
            settableChannelsCount++;
        }
    }

    return settableChannelsCount == preferredStereoChannels.count;
}

- (BOOL)setMasterVolume:(Float32)volume
           forDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;

    AudioObjectPropertyAddress address = {
        kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(Float32);

    theStatus = AudioHardwareServiceSetPropertyData(self.deviceID,
                                                    &address,
                                                    0,
                                                    NULL,
                                                    theSize,
                                                    &volume);

    if (noErr == theStatus)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)isMasterVolumeMutedForDirection:(AMCoreAudioDirection)theDirection
{
    return [self isChannelMuted:kAudioObjectPropertyElementMaster
                   andDirection:theDirection];
}

- (Float32)masterVolumeForDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    Float32 theVolumeScalar;

    AudioObjectPropertyAddress address = {
        kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(Float32);

    theStatus = AudioHardwareServiceGetPropertyData(self.deviceID,
                                                    &address,
                                                    0,
                                                    NULL,
                                                    &theSize,
                                                    &theVolumeScalar);

    if (noErr == theStatus)
    {
        return theVolumeScalar;
    }
    else
    {
        return 0.0;
    }
}

- (Float32)masterVolumeInDecibelsForDirection:(AMCoreAudioDirection)theDirection
{
    Float32 volumeInDecibels;
    NSArray *channels;
    UInt32 referenceChannel;

    if ([self canSetVolumeForChannel:kAudioObjectPropertyElementMaster
                        andDirection:theDirection])
    {
        referenceChannel = kAudioObjectPropertyElementMaster;
    }
    else
    {
        channels = [self preferredStereoChannelsForDirection:theDirection];

        if (channels.count == 0)
        {
            return -INFINITY;
        }

        referenceChannel = [channels[0] intValue];
    }

    volumeInDecibels = [self scalarToDecibels:[self masterVolumeForDirection:theDirection]
                                   forChannel:referenceChannel
                                 andDirection:theDirection];

    return volumeInDecibels;
}

#pragma mark - Volume Conversion Methods

- (Float32)scalarToDecibels:(Float32)volume
                 forChannel:(UInt32)theChannel
               andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    Float32 theVolumeDecibels;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyVolumeScalarToDecibels,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    theSize = sizeof(Float32);
    theVolumeDecibels = volume;

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theVolumeDecibels);

    if (noErr == theStatus)
    {
        return theVolumeDecibels;
    }
    else
    {
        return 0.0;
    }
}

- (Float32)decibelsToScalar:(Float32)volume
                 forChannel:(UInt32)theChannel
               andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    Float32 theVolumeScalar;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyVolumeDecibelsToScalar,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    theSize = sizeof(Float32);
    theVolumeScalar = volume;

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theVolumeScalar);

    if (noErr == theStatus)
    {
        return theVolumeScalar;
    }
    else
    {
        return 0.0;
    }
}

#pragma mark - Sample Rate Methods

- (Float64)actualSampleRate
{
    OSStatus theStatus;
    UInt32 theSize;
    Float64 theSampleRate;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyActualSampleRate,
        kAudioObjectPropertyScopeWildcard,
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(Float64);

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theSampleRate);

    if (noErr != theStatus)
    {
        return 0.0;
    }

    return theSampleRate;
}

- (Float64)nominalSampleRate
{
    OSStatus theStatus;
    UInt32 theSize;
    Float64 theSampleRate;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyNominalSampleRate,
        kAudioObjectPropertyScopeWildcard,
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(Float64);

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theSampleRate);

    if (noErr != theStatus)
    {
        return 0.0;
    }

    return theSampleRate;
}

- (NSArray *)nominalSampleRates
{
    if (!_nominalSampleRates)
    {
        OSStatus theStatus;
        UInt32 theSize;
        UInt32 numItems;
        UInt32 x;
        BOOL hasProperty;
        AudioValueRange *rangeArray;
        NSMutableArray *rv;
        NSArray *possibleRates;

        AudioObjectPropertyAddress address = {
            kAudioDevicePropertyAvailableNominalSampleRates,
            kAudioObjectPropertyScopeWildcard,
            kAudioObjectPropertyElementMaster
        };

        hasProperty = AudioObjectHasProperty(self.deviceID,
                                             &address);

        if (!hasProperty)
        {
            return @[];
        }

        theStatus = AudioObjectGetPropertyDataSize(self.deviceID,
                                                   &address,
                                                   0,
                                                   NULL,
                                                   &theSize);

        if (noErr != theStatus)
        {
            return @[];
        }

        // Sometimes an audio device will not support any sample rate.
        // For instance, this would be the case when an Aggregate Device
        // does not have any sub audio devices associated to it.
        // In this case, we will simply return an empty array

        if (theSize == 0)
        {
            return @[];
        }

        rangeArray = malloc(theSize);
        numItems = theSize / sizeof(AudioValueRange);

        theStatus = AudioObjectGetPropertyData(self.deviceID,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize,
                                               rangeArray);

        if (noErr != theStatus)
        {
            free(rangeArray);

            return @[];
        }

        // A list of all the possible sample rates up to 192kHz
        // to be used in the case we receive a range (see below)

        possibleRates = @[@6400.0, @8000.0, @11025.0, @12000.0,
                          @16000.0, @22050.0, @24000.0, @32000.0,
                          @44100.0, @48000.0, @64000.0, @88200.0,
                          @96000.0, @128000.0, @176400.0, @192000.0];

        // Initialize mutable array

        rv = [NSMutableArray array];

        // Populate mutable array

        for (x = 0; x < numItems; x++)
        {
            if (rangeArray[x].mMinimum < rangeArray[x].mMaximum)
            {
                /*!
                   We got a range.

                   This is the case in some cheap audio devices such as:

                        - CS50/CS60-USB Headset

                   or virtual audio drivers such as:

                        - "System Audio Recorder" (installed by WonderShare AllMyMusic)
                 */

                NSRange subArrayRange = NSMakeRange([possibleRates indexOfObject:@(rangeArray[x].mMinimum)],
                                                    [possibleRates indexOfObject:@(rangeArray[x].mMaximum)] + 1);

                @try {
                    NSArray *subArray = [possibleRates subarrayWithRange:subArrayRange];

                    for (id sampleRate in subArray)
                    {
                        [rv addObject:sampleRate];
                    }
                }
                @catch (NSException *exception)
                {
                    DLog(@"Unable to obtain sample rate ranges (%f, %f) due to an exception: %@", rangeArray[x].mMinimum, rangeArray[x].mMaximum, exception);
                }
            }
            else
            {
                // We did not get a range (this should be the most common case)

                [rv addObject:@(rangeArray[x].mMinimum)];
            }
        }

        free(rangeArray);

        _nominalSampleRates = [rv copy];
    }

    return _nominalSampleRates;
}

- (BOOL)setNominalSampleRate:(Float64)theRate
{
    OSStatus theStatus;
    UInt32 theSize;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyNominalSampleRate,
        kAudioObjectPropertyScopeWildcard,
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(Float64);

    theStatus = AudioObjectSetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           theSize,
                                           &theRate);

    if (noErr != theStatus)
    {
        DLog(@"Sample rate could not be changed to %f", theRate);

        return NO;
    }

    return YES;
}

#pragma mark - Clock Source Methods

- (NSString *)clockSourceForChannel:(UInt32)theChannel
                       andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    UInt32 theSourceID;
    BOOL hasProperty;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyClockSource,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    hasProperty = AudioObjectHasProperty(self.deviceID,
                                         &address);

    if (!hasProperty)
    {
        return AMCoreAudioDefaultClockSourceName;
    }

    theSize = sizeof(UInt32);
    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theSourceID);

    if (noErr == theStatus)
    {
        return TLD_ClockSourceNameForID(self.deviceID,
                                        theDirection,
                                        theChannel,
                                        theSourceID);
    }

    return nil;
}

- (NSArray *)clockSourcesForChannel:(UInt32)theChannel
                       andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    UInt32 *theSourceIDs;
    UInt32 numSources;
    UInt32 x;
    NSMutableArray *rv;
    BOOL hasProperty;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyClockSources,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    hasProperty = AudioObjectHasProperty(self.deviceID,
                                         &address);

    if (!hasProperty)
    {
        return nil;
    }

    theStatus = AudioObjectGetPropertyDataSize(self.deviceID,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize);

    if (noErr != theStatus)
    {
        return nil;
    }

    theSourceIDs = (UInt32 *)malloc(theSize);
    numSources = theSize / sizeof(UInt32);

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           theSourceIDs);

    if (noErr != theStatus)
    {
        free(theSourceIDs);

        return rv;
    }

    rv = [NSMutableArray arrayWithCapacity:numSources];

    for (x = 0; x < numSources; x++)
    {
        [rv addObject:TLD_ClockSourceNameForID(self.deviceID,
                                               theDirection,
                                               theChannel,
                                               theSourceIDs[x])];
    }

    free(theSourceIDs);

    return rv;
}

- (BOOL)setClockSource:(NSString *)theSource
            forChannel:(UInt32)theChannel
          andDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    UInt32 *theSourceIDs;
    UInt32 numSources;
    UInt32 x;
    BOOL hasProperty;
    NSString *sourceName;

    if (!theSource)
    {
        return NO;
    }

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyClockSources,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    hasProperty = AudioObjectHasProperty(self.deviceID,
                                         &address);

    if (!hasProperty)
    {
        return NO;
    }

    theStatus = AudioObjectGetPropertyDataSize(self.deviceID,
                                               &address,
                                               0,
                                               NULL,
                                               &theSize);

    if (noErr != theStatus)
    {
        return NO;
    }

    theSourceIDs = (UInt32 *)malloc(theSize);
    numSources = theSize / sizeof(UInt32);

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           theSourceIDs);

    if (noErr != theStatus)
    {
        free(theSourceIDs);

        return NO;
    }

    theSize = sizeof(UInt32);

    for (x = 0; x < numSources; x++)
    {
        sourceName = TLD_ClockSourceNameForID(self.deviceID,
                                              theDirection,
                                              theChannel,
                                              theSourceIDs[x]);

        if ([theSource isEqualTo:sourceName])
        {
            address.mSelector = kAudioDevicePropertyClockSource;

            theStatus = AudioObjectSetPropertyData(self.deviceID,
                                                   &address,
                                                   0,
                                                   NULL,
                                                   theSize,
                                                   &theSourceIDs[x]);
        }
    }

    free(theSourceIDs);

    return noErr == theStatus;
}

#pragma mark - Latency Methods

- (UInt32)deviceLatencyFramesForDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    UInt32 latencyFrames;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyLatency,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(UInt32);
    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &latencyFrames);

    if (noErr != theStatus)
    {
        return 0;
    }

    return latencyFrames;
}

- (UInt32)deviceSafetyOffsetFramesForDirection:(AMCoreAudioDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    UInt32 latencyFrames;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertySafetyOffset,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(UInt32);
    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &latencyFrames);

    if (noErr != theStatus)
    {
        return 0;
    }

    return latencyFrames;
}

#pragma mark - Hog Mode Methods

- (pid_t)hogModePid
{
    OSStatus theStatus;
    UInt32 theSize;
    pid_t pid;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyHogMode,
        kAudioObjectPropertyScopeWildcard,
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(pid_t);

    theStatus = AudioObjectGetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &pid);

    if (noErr != theStatus)
    {
        return 0;
    }

    return pid;
}

- (BOOL)setHogModePid:(pid_t)pid
{
    OSStatus theStatus;
    UInt32 theSize;

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyHogMode,
        kAudioObjectPropertyScopeWildcard,
        kAudioObjectPropertyElementMaster
    };

    theSize = sizeof(pid_t);

    theStatus = AudioObjectSetPropertyData(self.deviceID,
                                           &address,
                                           0,
                                           NULL,
                                           theSize,
                                           &pid);

    if (noErr != theStatus)
    {
        DLog(@"Hog mode could not be set to %d", pid);

        return NO;
    }

    return YES;
}

- (BOOL)setHogModePidToCurrentProcess
{
    pid_t pid = [[NSProcessInfo processInfo] processIdentifier];

    return [self setHogModePid:pid];
}

- (BOOL)unsetHogMode
{
    pid_t pid = -1;

    return [self setHogModePid:pid];
}

#pragma mark - Notification Methods

- (void)registerForNotifications
{
    OSStatus err;

    if (self.isRegisteredForNotifications)
    {
        [self unregisterForNotifications];
    }

    AudioObjectPropertyAddress address = {
        kAudioObjectPropertySelectorWildcard,
        kAudioObjectPropertyScopeWildcard,
        kAudioObjectPropertyElementWildcard
    };

    err = AudioObjectAddPropertyListener(self.deviceID,
                                         &address,
                                         TLD_AMCoreAudioDevicePropertyListener,
                                         (void *)CFBridgingRetain(self));

    if (err)
    {
        DLog(@"Error on AudioObjectAddPropertyListener %d\n", err);

        return;
    }

    self.isRegisteredForNotifications = (noErr == err);
}

- (void)unregisterForNotifications
{
    OSStatus err;

    if (self.deviceUID && self.isRegisteredForNotifications)
    {
        AudioObjectPropertyAddress address = {
            kAudioObjectPropertySelectorWildcard,
            kAudioObjectPropertyScopeWildcard,
            kAudioObjectPropertyElementWildcard
        };

        err = AudioObjectRemovePropertyListener(self.deviceID,
                                                &address,
                                                TLD_AMCoreAudioDevicePropertyListener,
                                                (__bridge void *)self);

        if (err)
        {
            DLog(@"Error on AudioObjectRemovePropertyListener %d\n", err);
        }

        self.isRegisteredForNotifications = (noErr != err);
    }
    else
    {
        self.isRegisteredForNotifications = NO;
    }
}

#pragma mark - Static C Functions

static UInt32 TLD_AMCoreAudioDirectionToScope(AMCoreAudioDirection theDirection)
{
    BOOL isPlayblack;

    isPlayblack = (theDirection == kAMCoreAudioDevicePlaybackDirection);

    return isPlayblack ? kAudioObjectPropertyScopeOutput : kAudioObjectPropertyScopeInput;
}

static AMCoreAudioDirection TLD_AMCoreAudioScopeToDirection(UInt32 scope)
{
    AMCoreAudioDirection theDirection;

    switch (scope)
    {
        case kAudioObjectPropertyScopeOutput:
            theDirection = kAMCoreAudioDevicePlaybackDirection;
            break;

        case kAudioObjectPropertyScopeInput:
            theDirection = kAMCoreAudioDeviceRecordDirection;
            break;

        default:
            theDirection = kAMCoreAudioDeviceInvalidDirection;
            break;
    }

    return theDirection;
}

static OSStatus TLD_AMCoreAudioDevicePropertyListener(AudioObjectID inObjectID,
                                                      UInt32 inNumberAddresses,
                                                      const AudioObjectPropertyAddress inAddresses[],
                                                      void *                           inClientData)
{
    AMCoreAudioDevice *self;
    AMCoreAudioDirection theDirection;

    self = (__bridge AMCoreAudioDevice *)(inClientData);
    theDirection = TLD_AMCoreAudioScopeToDirection(inAddresses->mScope);

    switch (inAddresses->mSelector)
    {
        case kAudioDevicePropertyNominalSampleRate:

            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(audioDeviceNominalSampleRateDidChange:)])
            {
                [self.delegate audioDeviceNominalSampleRateDidChange:self];
            }

            break;

        case kAudioDevicePropertyAvailableNominalSampleRates:

            // Let's invalidate cached nominal samplerates

            self.nominalSampleRates = nil;

            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(audioDeviceAvailableNominalSampleRatesDidChange:)])
            {
                [self.delegate audioDeviceAvailableNominalSampleRatesDidChange:self];
            }

            break;

        case kAudioDevicePropertyClockSource:

            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(audioDeviceClockSourceDidChange:forChannel:andDirection:)])
            {
                [self.delegate audioDeviceClockSourceDidChange:self
                                                    forChannel:inAddresses->mElement
                                                  andDirection:theDirection];
            }

            break;

        case kAudioDevicePropertyDeviceNameCFString:

            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(audioDeviceNameDidChange:)])
            {
                [self.delegate audioDeviceNameDidChange:self];
            }

            break;

        case kAudioObjectPropertyOwnedObjects:

            // Let's invalidate cached nominal samplerates

            self.nominalSampleRates = nil;

            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(audioDeviceListDidChange:)])
            {
                [self.delegate audioDeviceListDidChange:self];
            }

            break;

        case kAudioDevicePropertyVolumeScalar:

            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(audioDeviceVolumeDidChange:forChannel:andDirection:)])
            {
                [self.delegate audioDeviceVolumeDidChange:self
                                               forChannel:inAddresses->mElement
                                             andDirection:theDirection];
            }

            break;

        case kAudioDevicePropertyMute:

            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(audioDeviceMuteDidChange:forChannel:andDirection:)])
            {
                [self.delegate audioDeviceMuteDidChange:self
                                             forChannel:inAddresses->mElement
                                           andDirection:theDirection];
            }

            break;

        // Unhandled cases beyond this point

        case kAudioDevicePropertyBufferSize:
        case kAudioDevicePropertyBufferSizeRange:
        case kAudioDevicePropertyBufferFrameSize:
        case kAudioDevicePropertyStreamFormat:
        case kAudioDevicePropertyDeviceIsAlive:
        case kAudioDevicePropertyDeviceIsRunning:
        case kAudioDevicePropertyPlayThru:
        case kAudioDevicePropertyDataSource:
            break;
    }

    return noErr;
}

static NSString *TLD_ClockSourceNameForID(AudioObjectID theDeviceID,
                                          AMCoreAudioDirection theDirection,
                                          UInt32 theChannel,
                                          UInt32 theClockSourceID)
{
    OSStatus theStatus;
    UInt32 theSize;
    AudioValueTranslation theTranslation;
    NSString *theString;

    theTranslation.mInputData = &theClockSourceID;
    theTranslation.mInputDataSize = sizeof(UInt32);
    theTranslation.mOutputData = &theString;
    theTranslation.mOutputDataSize = sizeof(CFStringRef);
    theSize = sizeof(AudioValueTranslation);

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyClockSourceNameForIDCFString,
        TLD_AMCoreAudioDirectionToScope(theDirection),
        theChannel
    };

    theStatus = AudioObjectGetPropertyData(theDeviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theTranslation);

    if ((noErr == theStatus) && theString.length > 0)
    {
        return theString;
    }

    return AMCoreAudioDefaultClockSourceName;
}

static NSString *TLD_DeviceNameForID(AudioObjectID theDeviceID)
{
    OSStatus theStatus;
    NSString *theString;
    UInt32 theSize;

    theSize = sizeof(CFStringRef);

    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyDeviceNameCFString,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    theStatus = AudioObjectGetPropertyData(theDeviceID,
                                           &address,
                                           0,
                                           NULL,
                                           &theSize,
                                           &theString);

    if (noErr != theStatus || !theString)
    {
        return nil;
    }

    return theString;
}

@end
