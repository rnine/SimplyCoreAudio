//
//  EventSubscriber.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 20/09/2019.
//  Copyright © 2019 9Labs. All rights reserved.
//

import Foundation

/// The protocol any event subscriber must implement.
///
/// Typically, this will be a class that also happens to conform to the `Hashable` protocol.
public protocol EventSubscriber {
    /// This is the event handler.
    func eventReceiver(_ event: Event)

    /// The hash value.
    /// - SeeAlso: The `Hashable` protocol.
    var hashValue: Int { get }
}

func == (lhs: EventSubscriber, rhs: EventSubscriber) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
