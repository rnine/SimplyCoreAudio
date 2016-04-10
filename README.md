## AMCoreAudio

[![Version](http://cocoapod-badges.herokuapp.com/v/AMCoreAudio/badge.png)](http://cocoadocs.org/docsets/AMCoreAudio)
[![Platform](http://cocoapod-badges.herokuapp.com/p/AMCoreAudio/badge.png)](http://cocoadocs.org/docsets/AMCoreAudio)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![GitHub tag](https://img.shields.io/github/tag/rnine/AMCoreAudio.svg)](https://github.com/rnine/AMCoreAudio)

`AMCoreAudio` is a Swift wrapper for [Apple's Core Audio](https://developer.apple.com/library/mac/documentation/MusicAudio/Conceptual/CoreAudioOverview/) framework focusing on:

- Simplifying audio device enumeration
- Providing accessors for the most relevant audio device properties (i.e., device name, device manufacturer, device UID, volume, mute, sample rate, clock source, etc.)
- Subscribing to system and audio device specific notifications using delegation, etc.

`AMCoreAudio` is currently powering [AudioMate](http://audiomateapp.com) (recently open-sourced and available at https://github.com/The9Labs/AudioMate).

### Requirements

* Xcode 7 and Swift 2 (Objective-C support may be reintroduced anytime but it is not a high priority at this moment.)
* OS X 10.9 or later

**Note:** If you are targetting OS X 10.7 or 10.8 please use the [objc branch](https://github.com/rnine/AMCoreAudio/tree/objc).

### Documentation

* [AMCoreAudio Documentation](http://cocoadocs.org/docsets/AMCoreAudio/) (powered by [CocoaDocs.org](http://cocoadocs.org))

### Further Development & Patches

Do you want to contribute to the project? Please fork, patch, and then submit a pull request!

### Sample Projects

* [AudioMate](https://github.com/The9Labs/AudioMate) (a full-featured app recently open-sourced.)

### License

`AMCoreAudio` was written by Ruben Nine ([@sonicbee9](https://twitter.com/sonicbee9)) in 2013-2014 (open-sourced in March 2014) and is licensed under the [MIT](http://opensource.org/licenses/MIT) license. See [LICENSE.md](LICENSE.md).
