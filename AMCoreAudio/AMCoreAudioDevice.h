/*
   AMCoreAudioDevice.h
   AMCoreAudio

   Created by Ruben Nine on 7/29/13.
   Copyright (c) 2013, 2014 9Labs. All rights reserved.

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

@import Foundation;
@import CoreAudio.AudioHardwareBase;
#import "AMCoreAudioProtocols.h"

/*!
   @const AMCoreAudioDefaultClockSourceName
   @discussion The default clock source name when none is given.
 */
extern NSString *const AMCoreAudioDefaultClockSourceName;

/*!
   @class AMCoreAudioDevice
 */
@interface AMCoreAudioDevice : NSObject

/*!
    A delegate conforming to the AMCoreAudioDeviceDelegate protocol.
 */
@property (nonatomic, weak) id <AMCoreAudioDeviceDelegate> delegate;

/*!
   The cached device name. This may be useful in some situations where the class instance
   is pointing to a device that is no longer available, so we can still
   access its name.

   @return The cached device name.
 */
@property (readonly, strong) NSString *cachedDeviceName;

/*!
   A list of all the nominal sample rates supported by this audio device.

   @return An array of NSNumber objects with all the nominal sample rates.
 */
@property (readonly, nonatomic, strong) NSArray *nominalSampleRates;

/*!
   An audio device identifier.

   @note
   This identifier will change with system restarts.
   If you need an unique identifier that is persists between restarts,
   use deviceUID instead.

   @return An audio device identifier.
 */
@property (nonatomic, assign) AudioObjectID deviceID;

/*!
   A list of all the audio device IDs currently available in the system.

   The list also includes Aggregate and Multi-Output Devices.

   @return A set of audio device IDs wrapped as NSNumber objects.
 */
+ (NSSet *)allDeviceIDs;

/*!
   A list of all the audio devices currently available in the system.

   @note: The list also includes Aggregate and Multi-Output Devices.

   @return A set of AMCoreAudioDevice objects.
 */
+ (NSSet *)allDevices;

/*!
   A subset of allDevices containing only devices with inputs.

   @note: The list may also include Aggregate Devices.

   @return A set of AMCoreAudioDevice objects.
 */
+ (NSSet *)allInputDevices;

/*!
   A subset of allDevices containing only devices with outputs.

   @note: The list may also include Aggregate and Multi-Output Devices.

   @return A set of AMCoreAudioDevice objects.
 */
+ (NSSet *)allOutputDevices;

/*!
   Returns an AMCoreAudioDevice that matches the provided AudioObjectID,
   or nil if the AudioObjectID is invalid.

   @return An AMCoreAudioDevice object.
 */
+ (AMCoreAudioDevice *)deviceWithID:(AudioObjectID)theID;

/*!
   Returns an AMCoreAudioDevice that matches the provided audio UID,
   or nil if the UID is invalid.

   @return An AMCoreAudioDevice object.
 */
+ (AMCoreAudioDevice *)deviceWithUID:(NSString *)theUID;

/*!
   Returns an AMCoreAudioDevice that represents the default input device.

   @return An AMCoreAudioDevice object.
 */
+ (AMCoreAudioDevice *)defaultInputDevice;

/*!
   Returns an AMCoreAudioDevice that represents the default output device.

   @return An AMCoreAudioDevice object.
 */
+ (AMCoreAudioDevice *)defaultOutputDevice;

/*!
   Returns an AMCoreAudioDevice that represents the system's output device.

   @return An AMCoreAudioDevice object.
 */
+ (AMCoreAudioDevice *)systemOutputDevice;

/*!
   Promotes a device to become the default system output device, output device,
   or input device.

   Valid types are:

   kAudioHardwarePropertyDefaultSystemOutputDevice,
   kAudioHardwarePropertyDefaultOutputDevice,
   kAudioHardwarePropertyDefaultInputDevice.

   @return YES on success, NO otherwise.
 */

- (BOOL)setAsDefaultDevice:(AudioObjectPropertySelector)defaultDeviceType;

/*!
   Initializes an AMCoreAudioDevice by providing a valid AudioObjectID
   referencing an existing audio device in the system.

   @return An AMCoreAudioDevice object.
 */
- (AMCoreAudioDevice *)initWithDeviceID:(AudioObjectID)theID;


#pragma mark - General Device Information

/*!
   The audio device's name as reported by the system.

   @return An audio device's name.
 */
- (NSString *)deviceName;

/*!
   An system audio device unique identifier.

   This identifier is guaranted to uniquely identify a device in the system
   and will not change even after restarts. Two (or more) identical audio devices
   are also guaranteed to have unique identifiers.

   @return A string with the audio device's unique identifier.
 */
- (NSString *)deviceUID;

/*!
   The audio device's manufacturer.

   @return A string with the audio device's manufacturer name.
 */
- (NSString *)deviceManufacturer;

/*!
   The audio device's image file that can be used to represent the
   device visually

   @return An URL pointing to the image file
 */
- (NSURL *)deviceIconURL;

/*!
   The bundle ID for an application that provides a GUI for configuring
   the AudioDevice. By default, the value of this property
   is the bundle ID for Audio MIDI Setup.

   @return A NSString pointing to the bundle ID
 */
- (NSString *)deviceConfigurationApplication;

/*!
    A human readable name for the channel number and direction specified.

   @return A NSString with the name of the channel.

 */
- (NSString *)nameForChannel:(UInt32)theChannel
                andDirection:(AMCoreAudioDirection)theDirection;


/*!
 Whether the device is alive.

 @return YES when the device is alive, NO otherwise.
 */
- (BOOL)isAlive;

/*!
 Whether the device is running.

 @return YES when the device is running, NO otherwise.
 */
- (BOOL)isRunning;

/*!
 Whether the device is running somewhere.

 @return YES when the device is running somewhere, NO otherwise.
 */
- (BOOL)isRunningSomewhere;

#pragma mark - Clock Source Methods

/*!
   The clock source name for the channel number and direction specified.

   @return A NSString with the clock source name.

 */
- (NSString *)clockSourceForChannel:(UInt32)theChannel
                       andDirection:(AMCoreAudioDirection)theDirection;

/*!
   A list of clock source names for the channel number and direction specified.

   @return A NSArray containing all the clock source names.

 */
- (NSArray *)clockSourcesForChannel:(UInt32)theChannel
                       andDirection:(AMCoreAudioDirection)theDirection;

/*!
   Sets the clock source for a channel and direction.

   @note The clock source is given by name.

   @return YES on success, or NO otherwise.
 */
- (BOOL)setClockSource:(NSString *)theSource
            forChannel:(UInt32)theChannel
          andDirection:(AMCoreAudioDirection)theDirection;


#pragma mark - Latency Methods

/*!
   The latency in frames for the specified direction.

   @return The amount of frames as a UInt32 value.
 */
- (UInt32)deviceLatencyFramesForDirection:(AMCoreAudioDirection)theDirection;

/*!
   The safety offset frames for the specified direction.

   @return The amount of frames as a UInt32 value.
 */
- (UInt32)deviceSafetyOffsetFramesForDirection:(AMCoreAudioDirection)theDirection;


#pragma mark - Input/Output Layout Methods

/*!
   An array listing the number of channels per stream in a given direction.

   @return An NSArray containing the list of channels.
 */
- (NSArray *)channelsByStreamForDirection:(AMCoreAudioDirection)theDirection;

/*!
    The number of channels for a given direction.

   @return An UInt32 value.
 */
- (UInt32)channelsForDirection:(AMCoreAudioDirection)theDirection;

/*!
   Whether the device has only inputs but no outputs.

   @return YES when the device is input only, NO otherwise.
 */
- (BOOL)isInputOnlyDevice;

/*!
   Whether the device has only outputs but no inputs.

   @return YES when the device is output only, NO otherwise.
 */
- (BOOL)isOutputOnlyDevice;


#pragma mark - Individual Channel Methods

/*!
   A AMCoreAudioVolumeInfo struct containing information about
   a particular channel and direction combination.

   @return A AMCoreAudioVolumeInfo struct.
 */

- (AMCoreAudioVolumeInfo)volumeInfoForChannel:(UInt32)theChannel
                                 andDirection:(AMCoreAudioDirection)theDirection;

/*!
   The (scalar) volume for a given channel and direction.

   @return The scalar volume as a Float32 value.
 */
- (Float32)volumeForChannel:(UInt32)theChannel
               andDirection:(AMCoreAudioDirection)theDirection;

/*!
   The volume in decibels (dbFS) for a given channel and direction.

   @return The volume in decibels as a Float32 value.
 */
- (Float32)volumeInDecibelsForChannel:(UInt32)theChannel
                         andDirection:(AMCoreAudioDirection)theDirection;

/*!
   Sets the channel's volume for a given direction.

   @return YES on success, NO otherwise.
 */
- (BOOL)setVolume:(Float32)theVolume
       forChannel:(UInt32)theChannel
     andDirection:(AMCoreAudioDirection)theDirection;

/*!
   Mutes a channel for a given direction.

   @return YES on success, NO otherwise.
 */
- (BOOL) setMute:(BOOL)isMuted
      forChannel:(UInt32)theChannel
    andDirection:(AMCoreAudioDirection)theDirection;

/*!
   Whether a channel is muted for a given direction.

   @return YES if muted, NO otherwise.
 */
- (BOOL)isChannelMuted:(UInt32)theChannel
          andDirection:(AMCoreAudioDirection)theDirection;

/*!
   Whether a channel's volume can be set for a given direction.

   @return YES if it can be set, NO otherwise.
 */
- (BOOL)canSetVolumeForChannel:(UInt32)theChannel
                  andDirection:(AMCoreAudioDirection)theDirection;

/*!
    Whether a channel can be muted for a given direction.

   @return YES if it can be muted, NO otherwise.
 */
- (BOOL)canMuteForChannel:(UInt32)theChannel
             andDirection:(AMCoreAudioDirection)theDirection;

/*!
   A list of channel numbers that best represent the preferred stereo channels
   used by this device (usually 1 and 2).

   @return An NSArray containing channel numbers.
 */

- (NSArray *)preferredStereoChannelsForDirection:(AMCoreAudioDirection)theDirection;


#pragma mark - Master Volume Methods

/*!
    Whether the master volume can be set for a given direction.

    @return YES when the volume can be set, NO otherwise.
 */
- (BOOL)canSetMasterVolumeForDirection:(AMCoreAudioDirection)theDirection;

/*!
   Whether the master volume can be muted for a given direction.

   @return YES when the volume can be muted, NO otherwise.
 */
- (BOOL)canMuteMasterVolumeForDirection:(AMCoreAudioDirection)theDirection;

/*!
    Sets the master volume for a given direction.

   @return YES on success, NO otherwise.
 */
- (BOOL)setMasterVolume:(Float32)volume
           forDirection:(AMCoreAudioDirection)theDirection;

/*!
   Whether the volume is muted for a given direction.

   @return YES if muted, NO otherwise.
 */
- (BOOL)isMasterVolumeMutedForDirection:(AMCoreAudioDirection)theDirection;

/*!
   The master scalar volume for a given direction.

   @return The scalar volume as a Float32.
 */
- (Float32)masterVolumeForDirection:(AMCoreAudioDirection)theDirection;

/*!
   The master volume in decibels for a given direction.

   @return The volume in decibels as a Float32.
 */
- (Float32)masterVolumeInDecibelsForDirection:(AMCoreAudioDirection)theDirection;


#pragma mark - Volume Conversion Methods

/*!
   Converts a scalar volume to a decibel (dbFS) volume
   for the given channel and direction.

   @return The converted decibel value as a Float32.
 */
- (Float32)scalarToDecibels:(Float32)volume
                 forChannel:(UInt32)theChannel
               andDirection:(AMCoreAudioDirection)theDirection;

/*!
   Converts a relative decibel (dbFS) volume to a scalar volume
   for the given channel and direction.

   @return The converted scalar value as a Float32.
 */
- (Float32)decibelsToScalar:(Float32)volume
                 forChannel:(UInt32)theChannel
               andDirection:(AMCoreAudioDirection)theDirection;


#pragma mark - Sample Rate Methods

/*!
   The actual audio device's sample rate.

   @return A Float64 number.
 */
- (Float64)actualSampleRate;

/*!
   The nominal audio device's sample rate.

   @return A Float64 number.
 */
- (Float64)nominalSampleRate;

/*!
   Sets the nominal sample rate.

   @return YES on success, NO otherwise.
 */
- (BOOL)setNominalSampleRate:(Float64)theRate;

#pragma mark - Hog Mode

/*!
   Indicates the pid that currently owns exclusive access to the
   AudioDevice or a value of -1 indicating that the device is currently
   available to all processes.

   @return a pid_t value.
 */
- (pid_t)hogModePid;

/*!
   Attempts to set the pid that currently owns exclusive access to the
   AudioDevice.

   @return YES on success, NO otherwise.
 */
- (BOOL)setHogModePid:(pid_t)pid;

/*!
   Attempts to set the pid that currently owns exclusive access to the
   AudioDevice to the current process.

   @return YES on success, NO otherwise.
 */
- (BOOL)setHogModePidToCurrentProcess;

/*!
   Attempts to make the device available to all processes by setting
   the hog mode to -1.

   @return YES on success, NO otherwise.
 */
- (BOOL)unsetHogMode;

#pragma mark - Notification Methods

/*!
   Registers the audio device for notifications.

   @note
   By default, all audio devices are automatically registered for notifications.
   Use this together with unregisterForNotifications to enable/disable notifications
   whenever is more convenient for you.
 */
- (void)registerForNotifications;

/*!
   Unregisters the audio device for notifications when we are no longer interested.

   @note
   AMCoreAudioDevice objects are automatically unregistered for notifications when deallocated.
   Use this together with registerForNotifications to enable/disable notifications
   whenever is more convenient for you.
 */
- (void)unregisterForNotifications;

@end
