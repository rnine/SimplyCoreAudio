## Changelog

| Version       | Description   | Date     |
| -------------:|:------------- |:--------:|
| 1.5           | Adding support for modules so `AMCoreAudio` can be included using the new @import directive.| July 6th, 2015|
| 1.4.3         | Adding AMCoreAudioDevice -isRunning, -isRunningSomewhere, -isAlive| May 24th, 2015|
|               | Adding audioDeviceIsAliveDidChange:, audioDeviceIsRunningDidChange: and audioDeviceIsRunningSomewhereDidChange: methods to AMCoreAudioDeviceDelegate protocol.||
| 1.4.2         | Adding localizable strings support for AMCoreAudioDevice -formattedSampleRate:useShortFormat:| March 7th, 2015|
| 1.4.1         | Invalidating cached nominal sample rates after owned objects changes or the nominal sample rates changes.| October 27th, 2014|
| 1.4           | AMCoreAudio + AudioMate are now soulmates ;) | July 26th, 2014|
| 1.3.2         | Fixing AMCoreAudioManager sharedManager instantiation. | July 25th, 2014|
| 1.3.1         | Adding AMCoreAudioManager.h import to AMCoreAudio.h | July 25th, 2014|
| 1.3           | Adding AMCoreAudioManager, AMCoreAudioDevice+Formatters, and AMCoreAudioDevice+PreferredDirections. | July 16th, 2014|
| 1.2           | Adding +allInputDevices and +allOutputDevices to AMCoreAudioDevice. | June 28th, 2014|
| 1.1           | Adding Hog Mode methods (hogModePid, setHogModePid:, setHogModePidToCurrentProcess, and unsetHogMode.) | May 3rd, 2014|
| 1.0.1         | Check that AMCoreAudioHardware delegate responds to selector before actually calling it.<br>Minor updates in example project and comments. | March 28th, 2014|
| 1.0           | Initial Release. | March 24th, 2014|
