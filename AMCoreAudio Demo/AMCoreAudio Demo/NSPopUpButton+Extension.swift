//
//  NSPopUpButton+Extension.swift
//  AMCoreAudio Demo
//
//  Created by Ruben Nine on 30/10/2016.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Cocoa

extension NSPopUpButton {
    func item(withTag tag: Int) -> NSMenuItem? {
        let idx = indexOfItem(withTag: tag)
        return idx == -1 ? nil : item(at: idx)
    }

    func item(withRepresentedObject representedObject: Any?) -> NSMenuItem? {
        let idx = indexOfItem(withRepresentedObject: representedObject)
        return idx == -1 ? nil : item(at: idx)
    }

    func selectItem(withRepresentedObject representedObject: Any?) {
        let idx = indexOfItem(withRepresentedObject: representedObject)

        if idx != -1 {
            selectItem(at: idx)
        }
    }
}
