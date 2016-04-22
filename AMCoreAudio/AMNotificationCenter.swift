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
    var hashValue: Int { get }
}

func ==(lhs: AMEventSubscriber, rhs: AMEventSubscriber) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

// Notification Center

final public class AMNotificationCenter : NSObject {
    public static let defaultCenter = AMNotificationCenter()
    private var subscribersByEvent = [String: [AMEventSubscriber]]()

    private override init() {}

    public func subscribe(subscriber: AMEventSubscriber, eventType: AMEvent.Type) {
        let type = String(eventType)

        if subscribersByEvent[type] == nil {
            subscribersByEvent[type] = []
        }

        subscribersByEvent[type]!.append(subscriber)
    }

    public func unsubscribe(subscriber: AMEventSubscriber, eventType: AMEvent.Type) {
        let type = String(eventType)

        if var subscribers = subscribersByEvent[type] {
            if let idx = subscribers.indexOf({ (aSubscriber) -> Bool in aSubscriber == subscriber}) {
                subscribers.removeAtIndex(idx)
            }

            if subscribers.count == 0 {
                subscribersByEvent.removeValueForKey(type)
            }
        }
    }

    func publish(event: AMEvent) {
        let type = String(event.dynamicType)

        if let eventType = subscribersByEvent[type] {
            for subscriber in eventType {
                subscriber.eventReceiver(event)
            }
        }
    }
}
