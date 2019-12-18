//
//  NotificationController.swift
//  App
//
//  Created by Clément Cardonnel on 18/12/2019.
//

import Foundation
import UserNotifications
import os.log

final class NotificationController {
    
    static func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "com.boomerang.app.notification-feedback",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                if #available(iOS 12.0, *) {
                    os_log(.error, log: .notification, "Error while attempting to schedule notification with identifier: %{PUBLIC}@\nError description: %{PUBLIC}@", request.identifier, error.localizedDescription)
                } else {
                    print(error.localizedDescription)
                }
            } else {
                if #available(iOS 12.0, *) {
                    os_log(.info, log: .notification, "Successfully scheduled notification with identifier: %{PUBLIC}@", request.identifier)
                }
            }
        }
    }
    
    /// Request the notificaiton permission to the user.
    static func requestNotificationPermission() {
        // Ask for notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (didAllow, error) in
            if !didAllow {
                if #available(iOS 12.0, *) {
                    os_log(.info, log: .notification, "User has declined notifications")
                } else {
                    print("User has declined notifications")
                }
            }
            
            if let error = error {
                if #available(iOS 12.0, *) {
                    os_log(.error, log: .notification, "Notification request error: %{PUBLIC}@", error.localizedDescription)
                } else {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
}
