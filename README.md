## AMCoreAudio

`AMCoreAudio` is an Objective-C wrapper for Apple's CoreAudio framework focusing on:

- Simplifying audio device enumeration
- Providing accessors for the most relevant audio device properties (i.e., device name, device manufacturer, device UID, volume, mute, sample rate, clock source, etc.)
- Subscribing to system and audio device specific notifications using the delegate pattern.

`AMCoreAudio` is currently powering [AudioMate](http://audiomateapp.com) (in fact, that's where the AM prefix comes from!) and also plays an important role in another project of mine that is currently in development.

## Supported Notifications

### Hardware (a.k.a. system wide):

```objective-c
@protocol AMCoreAudioHardwareDelegate <NSObject>

@optional

/**
   Called whenever the list of audio devices in the system changes.

   @note If you want to receive notifications when the list of owned audio devices on Aggregate Devices and Multi-Output devices changes, then try using AMCoreAudioDevice instead.
 */
- (void)hardwareDeviceListChanged:(id)sender;

/**
    Called whenever the system's default input device changes.
 */
- (void)hardwareDefaultInputDeviceChanged:(id)sender;

/**
   Called whenever the system's default output device changes.
 */
- (void)hardwareDefaultOutputDeviceChanged:(id)sender;

/**
   Called whenever the system's default device changes.

   @note This is the audio device used for alerts, sound effects, etc.
 */
- (void)hardwareDefaultSystemDeviceChanged:(id)sender;

@end
```

### Per device:

```objective-c
@protocol AMCoreAudioDeviceDelegate <NSObject>

@optional

/**
    Called whenever the audio device's sample rate changes.
 */
- (void)audioDeviceNominalSampleRateDidChange:(id)sender;

/**
   Called whenever the audio device's list of nominal sample rates changes.

    @note This will typically happen on Aggregate Devices and Multi-Output devices when adding or removing other audio devices (either physical or virtual).
 */
- (void)audioDeviceAvailableNominalSampleRatesDidChange:(id)sender;

/**
    Called whenever the audio device's clock source changes for a given channel and direction.
 */
- (void)audioDeviceClockSourceDidChange:(id)sender forChannel:(UInt32)channel andDirection:(AMCoreAudioDirection)direction;

/**
   Called whenever the audio device's name changes.
 */
- (void)audioDeviceNameDidChange:(id)sender;

/**
   Called whenever the list of owned audio devices on this audio device changes.

   @note This will typically happen on Aggregate Devices and Multi-Output devices when adding or removing other audio devices (either physical or virtual).
 */
- (void)audioDeviceListDidChange:(id)sender;

/**
    Called whenever the audio device's volume for a given channel and direction changes.
 */
- (void)audioDeviceVolumeDidChange:(id)sender forChannel:(UInt32)channel andDirection:(AMCoreAudioDirection)direction;

/**
   Called whenever the audio device's mute state for a given channel and direction changes.
 */
- (void)audioDeviceMuteDidChange:(id)sender forChannel:(UInt32)channel andDirection:(AMCoreAudioDirection)direction;

@end
```

## Further Development & Patches ##

Do you want to contribute to the project? Please fork, patch, and then submit a pull request!

## TODO

- Improve example?

## License

`AMCoreAudio` was written by Ruben Nine ([@sonicbee9](https://twitter.com/sonicbee9)) in 2013-2014 (open-sourced in March 2014) and is licensed under the [MIT](http://opensource.org/licenses/MIT) license. See [LICENSE.md](LICENSE.md).

`AMCoreAudio` includes some utility code adapted from TheAmazingAudioEngine project in [AMCoreAudioUtilities.h](AMCoreAudio/AMCoreAudioUtilities.h) and [AMCoreAudioUtilities.c](AMCoreAudio/AMCoreAudioUtilities.c). [TheAmazingAudioEngine](https://github.com/TheAmazingAudioEngine/TheAmazingAudioEngine) is licensed under the [MIT license](https://github.com/TheAmazingAudioEngine/TheAmazingAudioEngine/blob/master/License.txt) and was written by Michael Tyson (A Tasty Pixel).
