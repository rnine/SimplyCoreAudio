## SimplyCoreAudio

[![Platform](https://img.shields.io/badge/Platforms-macOS%20-4E4E4E.svg?colorA=28a745)](https://github.com/rnine/SimplyCoreAudio)
[![Swift support](https://img.shields.io/badge/Swift-4.0%20%7C%204.2%20%7C%205.0%20%7C%205.1%20-lightgrey.svg?colorA=28a745&colorB=4E4E4E)](https://github.com/rnine/SimplyCoreAudio)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat&colorA=28a745&&colorB=4E4E4E)](https://github.com/apple/swift-package-manager)
[![GitHub tag](https://img.shields.io/github/tag/rnine/SimplyCoreAudio.svg)](https://github.com/rnine/SimplyCoreAudio)
[![License](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/rnine/SimplyCoreAudio/blob/develop/LICENSE.md)

`SimplyCoreAudio` is a Swift framework that aims to make [Core Audio](https://developer.apple.com/library/mac/documentation/MusicAudio/Conceptual/CoreAudioOverview/) use less tedious in macOS.

Here's a few things it can do:

- Simplifying audio device enumeration
- Providing accessors for the most relevant audio device properties (i.e., device name, device manufacturer, device UID, volume, mute, sample rate, clock source, etc.)
- Managing (physical and virtual) audio streams associated to an audio device
- Subscribing to audio hardware, audio device, and audio stream events
- etc.

### Requirements

- macOS 10.12 or later
- Xcode 12 or later
- Swift 4.0 or later

**Note:** If you are targeting macOS versions 10.7 or 10.8 please use the [objc branch](https://github.com/rnine/SimplyCoreAudio/tree/objc).

![Alt text](https://github.com/rnine/SimplyCoreAudio/raw/develop/images/screenshot.png?raw=true "SimplyCoreAudio Demo (Output tab)")

### Documentation

- [API Documentation](https://rnine.github.io/SimplyCoreAudio)

### Further Development & Patches

Do you want to contribute to the project? Please fork, patch, and then submit a pull request!

### Running Tests

Please make sure to install `NullAudio.driver` before attempting to run tests:

###  Installing `NullAudio.driver`

1. Unzip `NullAudio.driver.zip` included in `Tests/Extras`.
2. Copy `NullAudio.driver` to `/Library/Audio/Plug-Ins/HAL`.
3. Restart `macOS`.

### License

`SimplyCoreAudio` was written by Ruben Nine ([@rnine](https://github.com/rnine)) in 2013-2014 (open-sourced in March 2014) and is licensed under the [MIT](https://opensource.org/licenses/MIT) license. See [LICENSE.md](LICENSE.md).
