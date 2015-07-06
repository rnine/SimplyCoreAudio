//
//  AMCoreAudioHardware.h
//  AMCoreAudio
//
//  Created by Ruben Nine on 22/03/14.
//  Copyright (c) 2014 9Labs. All rights reserved.
//

@import Foundation;
#import "AMCoreAudioProtocols.h"

@interface AMCoreAudioHardware : NSObject

/*!
   A delegate conforming to the AMCoreAudioHardwareDelegate protocol.
 */
@property (nonatomic, weak) id<AMCoreAudioHardwareDelegate>delegate;

@end
