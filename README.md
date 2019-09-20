## AMCoreAudio

[![Platform](https://img.shields.io/badge/Platforms-macOS%20-4E4E4E.svg?colorA=28a745)](https://github.com/rnine/AMCoreAudio)
[![Swift support](https://img.shields.io/badge/Swift-4.0%20%7C%204.2%20%7C%205.0%20%7C%205.1%20-lightgrey.svg?colorA=28a745&colorB=4E4E4E)](https://github.com/rnine/AMCoreAudio)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat&colorA=28a745&&colorB=4E4E4E)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat&colorA=28a745&&colorB=4E4E4E)](https://github.com/apple/swift-package-manager)

[![Version](http://cocoapod-badges.herokuapp.com/v/AMCoreAudio/badge.png)](http://cocoadocs.org/docsets/AMCoreAudio)
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

- macOS 10.10
- Xcode 10.2
- Swift 4.0 / 4.2 / 5.0 / 5.1

**Note:** If you are targeting macOS versions 10.7 or 10.8 please use the [objc branch](https://github.com/rnine/AMCoreAudio/tree/objc).

![Alt text](https://github.com/rnine/AMCoreAudio/raw/develop/images/screenshot.png?raw=true "AMCoreAudio Demo (Output tab)")

### Documentation

- [API Documentation](https://rnine.github.io/AMCoreAudio)

### Further Development & Patches

Do you want to contribute to the project? Please fork, patch, and then submit a pull request!

### Sample Projects

- `AMCoreAudio Demo` (included in this repository)

### License

`AMCoreAudio` was written by Ruben Nine ([@sonicbee9](https://twitter.com/sonicbee9)) in 2013-2014 (open-sourced in March 2014) and is licensed under the [MIT](https://opensource.org/licenses/MIT) license. See [LICENSE.md](LICENSE.md).
