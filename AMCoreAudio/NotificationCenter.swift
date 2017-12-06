//
//  NotificationCenter.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 17/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Foundation


/**
    The protocol that any events must implement.
 
    An event conforming to this protocol may be a class, a struct or an enum. In AMCoreAudio, 
    we will be relying on enums, since they are very lightweight yet expressive enough (we can
    pass arguments to them.)
 */
public protocol Event {}

/**
    The protocol any event subscriber must implement.
 
    Typically, this will be a class that also happens to conform to the `Hashable` protocol.
 */
public protocol EventSubscriber {

    /**
        This is the event handler.
     */
    func eventReceiver(_ event: Event)

    /**
        The hash value.
        - SeeAlso: The `Hashable` protocol.
     */
    var hashValue: Int { get }
}

func ==(lhs: EventSubscriber, rhs: EventSubscriber) -> Bool {

    return lhs.hashValue == rhs.hashValue
}


private struct EventSubscriberDescriptor {

    var subscriber: EventSubscriber
    var queue: DispatchQueue?
}


// MARK: - NotificationCenter

/**
    This is `AMCoreAudio`'s de facto pub-sub system.
 */
final public class NotificationCenter {

    private var subscriberDescriptorsByEvent = [String: [EventSubscriberDescriptor]]()

    private init() {}

    /**
        Returns a singleton `NotificationCenter` instance.
     */
    public static let defaultCenter = NotificationCenter()

    /**
        Allows a subscriber conforming to the `EventSubscriber` protocol to receive events of
        the type specified by `eventType`.
     
        - Parameter subscriber: Any object conforming to the `EventSubscriber` protocol.
        - Parameter eventType: A class, struct or enum type conforming to the `Event` protocol.
        - Parameter dispatchQueue: (optional) A dispatch queue to use for delivering the events.
     */
    public func subscribe(_ subscriber: EventSubscriber, eventType: Event.Type, dispatchQueue: DispatchQueue? = nil) {

        let type = String(describing: eventType)

        if subscriberDescriptorsByEvent[type] == nil {
            subscriberDescriptorsByEvent[type] = []

            if eventType is AudioHardwareEvent.Type {
                AudioHardware.sharedInstance.enableDeviceMonitoring()
            }
        }

        let descriptor = EventSubscriberDescriptor(subscriber: subscriber, queue: dispatchQueue)

        subscriberDescriptorsByEvent[type]!.append(descriptor)
    }

    /**
        Removes a subscriber from the subscription to events of a specified `eventType`.

        - Parameter subscriber: Any object conforming to the `EventSubscriber` protocol.
        - Parameter eventType: A class, struct or enum type conforming to the `Event` protocol.
     */
    public func unsubscribe(_ subscriber: EventSubscriber, eventType: Event.Type) {

        let type = String(describing: eventType)

        if var subscribers = subscriberDescriptorsByEvent[type] {
            if let idx = subscribers.index(where: { (aSubscriber) -> Bool in aSubscriber.subscriber == subscriber}) {
                subscribers.remove(at: idx)
            }

            if subscribers.count == 0 {
                subscriberDescriptorsByEvent.removeValue(forKey: type)

                if eventType is AudioHardwareEvent.Type {
                    AudioHardware.sharedInstance.disableDeviceMonitoring()
                }
            }
        }
    }

    /**
        Publishes an event. The event is delivered to all its subscribers.

        - Parameter event: The event conforming to the `Event` protocol to publish.
     */
    func publish(_ event: Event) {

        let type = String(describing: Swift.type(of: event))

        if let subscriberDescriptors = subscriberDescriptorsByEvent[type] {
            for descriptor in subscriberDescriptors {
                // If queue is present, we will dispatch the event in that queue,
                // otherwise, we will just dispatch the event in whatever happens to be the current
                // queue.
                if let queue = descriptor.queue {
                    queue.async(execute: { 
                        descriptor.subscriber.eventReceiver(event)
                    })
                } else {
                    descriptor.subscriber.eventReceiver(event)
                }
            }
        }
    }
}
