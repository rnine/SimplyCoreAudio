//
//  AppDelegate.swift
//  AMCoreAudio Demo
//
//  Created by Ruben Nine on 30/10/2016.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Cocoa
import AMCoreAudio

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    private let audioHardware = AMAudioHardware.sharedInstance

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        audioHardware.enableDeviceMonitoring()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application

        audioHardware.disableDeviceMonitoring()
    }


}

