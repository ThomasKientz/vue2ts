//
//  OSLog+Custom.swift
//  App
//
//  Created by Clément Cardonnel on 18/12/2019.
//

import Foundation
import os.log

/*
 Define custom OSLog categories for better segmentation through the logs.
 */
extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let itemDecoding = OSLog(subsystem: subsystem, category: "Item Decoding")
    static let backgroundUpload = OSLog(subsystem: subsystem, category: "Background Upload")
    static let notification = OSLog(subsystem: subsystem, category: "Notification")
}
