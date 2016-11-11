## AMCoreAudio

[![Version](http://cocoapod-badges.herokuapp.com/v/AMCoreAudio/badge.png)](http://cocoadocs.org/docsets/AMCoreAudio)
[![Platform](http://cocoapod-badges.herokuapp.com/p/AMCoreAudio/badge.png)](http://cocoadocs.org/docsets/AMCoreAudio)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![GitHub tag](https://img.shields.io/github/tag/rnine/AMCoreAudio.svg)](https://github.com/rnine/AMCoreAudio)
[![License](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/rnine/AMCoreAudio/blob/develop/LICENSE.md)

`AMCoreAudio` is a Swift framework that aims to make [Core Audio](https://developer.apple.com/library/mac/documentation/MusicAudio/Conceptual/CoreAudioOverview/) use less tedious in macOS.

Here's a few things it can do:

- Simplifying audio device enumeration
- Providing accessors for the most relevant audio device properties (i.e., device name, device manufacturer, device UID, volume, mute, sample rate, clock source, etc.)
- Managing (physical and virtual) audio streams associated to an audio device
- Subscribing to audio hardware, audio device, and audio stream events
- etc.

### Requirements

* Xcode 8 and Swift 3
* OS X 10.9 or later

**Note:** If you are targeting OS X version 10.7 or 10.8 please use the [objc branch](https://github.com/rnine/AMCoreAudio/tree/objc).

![Alt text](https://github.com/rnine/AMCoreAudio/raw/develop/images/screenshot.png?raw=true "AMCoreAudio Demo (Output tab)")

### Documentation

* [AMCoreAudio Documentation](http://rnine.github.io/AMCoreAudio) (powered by [jazzy ♪♫](https://github.com/realm/jazzy) and [GitHub Pages](https://pages.github.com))

### Further Development & Patches

Do you want to contribute to the project? Please fork, patch, and then submit a pull request!

### Sample Projects

* `AMCoreAudio Demo` (included in this repository)
* [AudioMate](https://github.com/The9Labs/AudioMate) (a full-featured app recently open-sourced)

### License

`AMCoreAudio` was written by Ruben Nine ([@sonicbee9](https://twitter.com/sonicbee9)) in 2013-2014 (open-sourced in March 2014) and is licensed under the [MIT](http://opensource.org/licenses/MIT) license. See [LICENSE.md](LICENSE.md).
