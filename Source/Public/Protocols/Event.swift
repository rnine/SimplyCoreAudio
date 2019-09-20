//
//  Event.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 20/09/2019.
//  Copyright © 2019 9Labs. All rights reserved.
//

import Foundation

/// The protocol that any events must implement.
///
/// An event conforming to this protocol may be a class, a struct or an enum. In AMCoreAudio,
/// we will be relying on enums, since they are very lightweight yet expressive enough (we can
/// pass arguments to them.)
public protocol Event {}
