//
//  AMNotificationCenter.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 17/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Foundation

// MARK: - AMNotificationCenter Protocols

/**
    The protocol that any events must implement.
 
    An event conforming to this protocol may be a class, a struct or an enum. In AMCoreAudio, 
    we will be relying on enums, since they are very lightweight yet expressive enough (we can
    pass arguments to them.)
 */
public protocol AMEvent {}

/**
    The protocol any event subscriber must implement.
 
    Typically, this will be a class that also happens to conform to the `Hashable` protocol.
 */
public protocol AMEventSubscriber {
    /**
        This is the event handler.
     */
    func eventReceiver(event: AMEvent)

    /**
        The hash value.
        - SeeAlso: The `Hashable` protocol.
     */
    var hashValue: Int { get }
}

func ==(lhs: AMEventSubscriber, rhs: AMEventSubscriber) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

private struct AMEventSubscriberAndQueue {
    var subscriber: AMEventSubscriber
    var queue: dispatch_queue_t?
}

// MARK: - AMNotificationCenter

/**
    `AMNotificationCenter` is AMCoreAudio's de facto pub-sub system.
 */
final public class AMNotificationCenter : NSObject {
    private var subscribersByEvent = [String: [AMEventSubscriberAndQueue]]()

    private override init() {}

    /**
        Returns a singleton `AMNotificationCenter` instance.
     */
    public static let defaultCenter = AMNotificationCenter()

    /**
        Allows a subscriber conforming to the `AMEventSubscriber` protocol to receive events of
        the type specified by `eventType`.
     
        - Parameter subscriber: Any object conforming to the `AMEventSubscriber` protocol.
        - Parameter eventType: A class, struct or enum type conforming to the `AMEvent` protocol.
        - Parameter dispatchQueue: (optional) A dispatch queue to use for delivering the events.
     */
    public func subscribe(subscriber: AMEventSubscriber, eventType: AMEvent.Type, dispatchQueue: dispatch_queue_t? = nil) {
        let type = String(eventType)

        if subscribersByEvent[type] == nil {
            subscribersByEvent[type] = []
        }

        let subscriberAndQueue = AMEventSubscriberAndQueue(subscriber: subscriber, queue: dispatchQueue)

        subscribersByEvent[type]!.append(subscriberAndQueue)
    }

    /**
        Removes a subscriber from the subscription to events of a specified `eventType`.

        - Parameter subscriber: Any object conforming to the `AMEventSubscriber` protocol.
        - Parameter eventType: A class, struct or enum type conforming to the `AMEvent` protocol.
     */
    public func unsubscribe(subscriber: AMEventSubscriber, eventType: AMEvent.Type) {
        let type = String(eventType)

        if var subscribers = subscribersByEvent[type] {
            if let idx = subscribers.indexOf({ (aSubscriber) -> Bool in aSubscriber.subscriber == subscriber}) {
                subscribers.removeAtIndex(idx)
            }

            if subscribers.count == 0 {
                subscribersByEvent.removeValueForKey(type)
            }
        }
    }

    /**
        Publishes an event. The event is delivered to all its subscribers.

        - Parameter event: The event conforming to the `AMEvent` protocol to publish.
     */
    func publish(event: AMEvent) {
        let type = String(event.dynamicType)

        if let eventType = subscribersByEvent[type] {
            for subscriberAndQueue in eventType {
                if let queue = subscriberAndQueue.queue {
                    dispatch_async(queue, { 
                        subscriberAndQueue.subscriber.eventReceiver(event)
                    })
                } else {
                    subscriberAndQueue.subscriber.eventReceiver(event)
                }
            }
        }
    }
}
