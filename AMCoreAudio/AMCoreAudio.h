/*
   AMCoreAudio.h
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

//! Project version number for AMCoreAudio.
FOUNDATION_EXPORT double AMCoreAudioVersionNumber;

//! Project version string for AMCoreAudio.
FOUNDATION_EXPORT const unsigned char AMCoreAudioVersionString[];

#import "AMCoreAudioTypes.h"
#import "AMCoreAudioHardware.h"
#import "AMCoreAudioDevice.h"
#import "AMCoreAudioManager.h"
#import "AMCoreAudioProtocols.h"
#import "AMCoreAudioDevice+Formatters.h"
#import "AMCoreAudioDevice+PreferredDirections.h"