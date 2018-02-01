//
//  ColorServiceManagerDelegate.swift
//  connectedColors
//
//  Created by user on 1/30/18.
//  Copyright © 2018 user. All rights reserved.
//

import Foundation

protocol AnonServiceManagerDelegate {
    func connectedDevicesChanged(manager: AnonServiceManager, connectedDevices: [String])
    func newMessageReceived(manager: AnonServiceManager, messageDictionary: NSDictionary)
}

