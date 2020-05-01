## Changelog

| Version        | Description| Date     |
| -------------:|:------------- |:--------:|
| 3.4              | Added SPM support. | May 1st, 2020 |
|                    | Added `isMasterChannelMuted(direction:`, `dataSource(direction:)`, `dataSources(direction:)` and `dataSourceName(dataSourceID:direction:)`. ||
|                    | Renamed `canMuteVirtualMasterChannel(direction:)` to `canMuteMasterChannel(direction:)`. ||
|                    | Added `latency` to `AudioStream`. ||
|                    | Removed `name` property from `AudioStream`. ||
|                    | Exposed `name` property from `AudioObject` publicly.||
|                    | Fixed some thread safety issues by using a serial queue to subscribe to audio property listeners (@fbarbat.)||
| 3.3.1           | Minor cleanup. | June 19th, 2019 |
| 3.3              | Added Swift 5 support.| May 12th, 2019 |
| 3.2.1           | Added Swift 4.2 support.| September 4th, 2018 |
|                    | Added `hogModeDidChange(audioDevice:)` notification. | |
| 3.2              | Added Swift 4 support.| February 26th, 2018 |
| 3.1.3           | Removed unnecessary `channel` and `direction` arguments from AudioDevice `setClockSourceID(_:)`. | September 26th, 2017 |
|                    | Improved documentation. | |
| 3.1.2           | Removed `channel` and `direction` arguments from `clockSourceID()` , `clockSourceName()`,  `clockSourceIDs()`, and `clockSourceNames()`. | September 12th, 2017 |
|                    | Removed `channel` and `direction` from  `clockSourceDidChange(audioDevice:)` signature in `AudioDeviceEvent` protocol. | |
| 3.1.1           | Fixed broken `setDefaultDevice(_:)` functionality (reported by @DerButtsche.) | March 13th, 2017 |
| 3.1              | Deprecated the `AM` prefix in all classes/enums/structs and modernized many function signatures. Old names and signatures are marked for removal in 3.2. | December 21st, 2016 |
|                    | Added `isJackConnectedDidChange(audioDevice:)` notification. | |
|                    | Added `preferredChannelsForStereoDidChange(audioDevice)` notification. | |
|                    | Added some LFE (Low Frequency Effects) functions and variables. | |
|                    | Added `setPreferredChannelsForStereo(channels:direction:)`. | |
|                    | Changed `nominalSampleRate()` and `actualSampleRate()` implementations so they return nil in the event 0 is returned by Core Audio. | |
|                    | Improved `volumeInfo(channel:direction:)` implementation so it does not return a `VolumeInfo` struct unless it is actually populated with any valid values. | |
|                    | Removed the need to manually enable and disable device monitoring in `AudioHardware`. | |
|                    | Added `TerminalType` and `StereoPair` enums. | |
|                    | Changed all enum values to camelCase to follow Swift 3 conventions. | |
|                    | Removed `.invalid` direction (it was only used internally and is no longer required.) | |
|                    | Added new demo project. | |
| 3.0.1           | Added `AMCoreAudio` `setHogMode()` and removed `setHogModePidToCurrentProcess()` and `setHogModePID(_:)` | October 30th, 2016 |
|                    | Fixed `unsetHogMode()` so it does not actually try to request hog mode instead of unsetting it when hog mode is not set. | |
|                    | Changed `AMCoreAudio` `channelsForDirection(_:)` to calculate the total channel count based on the sum of channels in every stream's physical format. Old implementation is still available as `layoutChannelsForDirection(_:)` | |
| 3.0              | Added Swift 3 support and new Pub/Sub notification system. | October 5th, 2016 |
| 2.0.10         | Fixed `AMCoreAudio` `scalarToDecibels(_:forChannel:andDirection:)` and `decibelsToScalar(_:forChannel:andDirection:)` conversions. | January 19th, 2016 |
| 2.0.9           | Added `AMCoreAudioDevice+Formatters` extension. | January 18th, 2016 |
| 2.0.8           | Added XCode 7 compatibility. | September 17th, 2015 |
| 2.0.7           | Minor fixes. | July 13th, 2015 |
| 2.0.6           | Marked protocol methods in `AMCoreAudioManagerDelegate`, `AMCoreAudioDeviceDelegate`, and `AMCoreAudioHardwareDelegate` as optional by providing default implementations in protocol extensions. | July 13th, 2015 |
| 2.0.5           | Stop using deprecated APIs: `AudioHardwareServiceSetPropertyData` and `AudioHardwareServiceGetPropertyData.` | July 13th, 2015 |
| 2.0.4           | Fixed `AMCoreAudioDevice(deviceID:)` initializer by reimplementing its core functionality in C. | July 13th, 2015 |
| 2.0.3           | Fixed that `AMCoreAudioHardware` `delegate` was not declared as a public variable. | July 13th, 2015 |
| 2.0.2           | Fixed that `AMCoreAudio.allOutputDevices()` was not declared as a public method. | July 13th, 2015 |
| 2.0.1           | `preferredStereoChannelsForDirection(Direction)` now returns an optional `UInt32` array. | July 12th, 2015 |
|                    | Misc improvements in documentation. | |
| 2.0              | First Swift-only release. | July 12th, 2015 |
|                    | Added `deviceManufacturer()`, `deviceIsHidden()`, `transportType()`, `ownedObjectIDs()`, `controlList()`, `relatedDevices()`, `classID()` to `AMCoreAudioDevice`. | |
|                    | Changed `channelsForDirection(Direction)` so it is based on `kAudioDevicePropertyPreferredChannelLayout`. | |
|                    | Audio device and audio hardware notifications now run on their own GCD queues. | |
|                    | `AMCoreAudioDirection` is now `Direction`. `AMCoreAudioVolumeInfo` is now `VolumeInfo`. | |
|                    | Many functions DO return optionals now. | |
| 1.5              | Added support for modules so `AMCoreAudio` can be included using the new `@import` directive. | July 6th, 2015 |
| 1.4.3           | Added `AMCoreAudioDevice` `-isRunning`, `-isRunningSomewhere`, `-isAlive` | May 24th, 2015 |
|                    | Added `audioDeviceIsAliveDidChange:`, `audioDeviceIsRunningDidChange:` and `audioDeviceIsRunningSomewhereDidChange:` methods to `AMCoreAudioDeviceDelegate` protocol. | |
| 1.4.2           | Added localizable strings support for `AMCoreAudioDevice` `-formattedSampleRate:useShortFormat:` | March 7th, 2015 |
| 1.4.1           | Invalidating cached nominal sample rates after owned objects changes or the nominal sample rates changes. | October 27th, 2014 |
| 1.4              | `AMCoreAudio` + `AudioMate` are now soulmates ;) | July 26th, 2014 |
| 1.3.2           | Fixed `AMCoreAudioManager` `sharedManager` instantiation. | July 25th, 2014 |
| 1.3.1           | Added `AMCoreAudioManager.h` import to `AMCoreAudio.h` | July 25th, 2014 |
| 1.3              | Added `AMCoreAudioManager`, `AMCoreAudioDevice+Formatters`, and `AMCoreAudioDevice+PreferredDirections`. | July 16th, 2014 |
| 1.2              | Added `+allInputDevices` and `+allOutputDevices` to `AMCoreAudioDevice`. | June 28th, 2014 |
| 1.1              | Added Hog Mode methods (`hogModePid`, `setHogModePid:`, `setHogModePidToCurrentProcess`, and `unsetHogMode`.) | May 3rd, 2014 |
| 1.0.1           | Check that `AMCoreAudioHardware` delegate responds to selector before actually calling it. | March 28th, 2014 |
|                    | Minor updates in example project and comments. | |
| 1.0              | Initial Release. | March 24th, 2014 |
