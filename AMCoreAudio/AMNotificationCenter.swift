//
//  AMNotificationCenter.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 17/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Foundation

// Notification Center Protocols

public protocol AMEvent {}

public protocol AMEventSubscriber {
    func eventReceiver(event: AMEvent)
}

// Notification Center

final public class AMNotificationCenter : NSObject {
    public static let defaultCenter = AMNotificationCenter()
    private var subscribers = [String: [AMEventSubscriber]]()

    private override init() {}

    public func subscribe(subscriber: AMEventSubscriber, eventType: AMEvent.Type) {
        let type = String(eventType)

        if subscribers[type] == nil {
            subscribers[type] = []
        }

        subscribers[type]!.append(subscriber)
    }

    func publish(event: AMEvent) {
        let type = String(event.dynamicType)

        if let subscribers = subscribers[type] {
            for subscriber in subscribers {
                subscriber.eventReceiver(event)
            }
        }
    }
}
