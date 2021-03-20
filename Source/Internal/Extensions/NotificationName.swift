//
//  NotificationName.swift
//  
//
//  Created by Ruben Nine on 20/3/21.
//

import Foundation

protocol NotificationName {
    var name: Notification.Name { get }
}

extension RawRepresentable where RawValue == String, Self: NotificationName {
    var name: Notification.Name {
        get { Notification.Name(rawValue) }
    }
}
