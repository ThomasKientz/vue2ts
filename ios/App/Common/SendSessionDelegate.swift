//
//  SendSessionDelegate.swift
//  App
//
//  Created by Clément Cardonnel on 17/12/2019.
//

import Foundation
import os.log

final class SendSessionDelegate: NSObject, URLSessionDataDelegate {
    
    let completionHandler: (() -> Void)?
    
    init(_ completionHandler: (() -> Void)? = nil) {
        self.completionHandler = completionHandler
        super.init()
    }
    
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if #available(iOS 12.0, *) {
            os_log(.debug, log: .backgroundUpload, "Session did finish events.")
        }
        
        completionHandler?()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .backgroundUpload, "Background task failed with error: %{PUBLIC}@", error.localizedDescription)
            }
            
            NotificationController.sendNotification(title: "Upload failed", body: error.localizedDescription)
        } else if let response = task.response {
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                if #available(iOS 12.0, *) {
                    os_log(.debug, log: .backgroundUpload, "Couldn't retrieve status code from response.")
                }
                NotificationController.sendNotification(title: "Upload failed", body: "Something went wrong.")
                return
            }
            
            if (200..<300).contains(statusCode) {
                if #available(iOS 12.0, *) {
                    let isFromRecreatedSession = completionHandler != nil
                    let recreatedDebugString = isFromRecreatedSession ? " from recreated session." : "."
                    os_log(.info, log: .backgroundUpload, "Background task succeeded with HTTP status code %{PUBLIC}d%{PUBLIC}@", statusCode, recreatedDebugString)
                }
                
                #if DEBUG
                NotificationController.sendNotification(
                    title: "Upload succeeded!",
                    body: "\(statusCode). \(completionHandler == nil ? "" : "I am from recreated session.")"
                )
                #endif
            } else {
                if #available(iOS 12.0, *) {
                    let isFromRecreatedSession = completionHandler != nil
                    let recreatedDebugString = isFromRecreatedSession ? " from recreated session." : "."
                    os_log(.info, log: .backgroundUpload, "Background task failed with HTTP status code %{PUBLIC}d%{PUBLIC}@", statusCode, recreatedDebugString)
                }
                
                // Failure! Should send notification
                #if DEBUG
                let errorMessage = "Something went wrong. \(statusCode)"
                #else
                let errorMessage = "Something went wrong."
                #endif
                NotificationController.sendNotification(title: "Upload failed", body: errorMessage)
            }
            
        }
    }
    
}
