//
//  IntentHandler.swift
//  IntentsExtension
//
//  Created by Clément Cardonnel on 13/01/2020.
//

import Intents
import os.log

class IntentHandler: INExtension, INSendMessageIntentHandling {
    
    // Check that the intent contain a message
    func resolveContent(for intent: INSendMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let text = intent.content,
            text.isEmpty == false {
            completion(INStringResolutionResult.success(with: text))
        }
        else {
            completion(INStringResolutionResult.needsValue())
        }
    }
    
    func handle(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        if #available(iOS 12.0, *) {
            os_log(.info, log: .siri, "Siri Intent invoked with message: %{PRIVATE}@", intent.content ?? "none")
        }
        
        /// Triggers the completion handler with the specified code
        func complete(code: INSendMessageIntentResponseCode) {
            let userActivity = NSUserActivity(activityType: String(describing: INSendMessageIntent.self))
            
            completion(
                INSendMessageIntentResponse(
                    code: code,
                    userActivity: userActivity
                )
            )
        }
        
        // Retrieve config
        let config = ConfigReader.loadConfig()
        
        // Check that we've got a valid token
        guard let token = config.emailTokens.first?.token else {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .siri, "Siri Intent completed with failure because no email was registered.")
            }
            
            // If not, we send the user to the app so that she logs herself.
            complete(code: .failureRequiringAppLaunch)
            
            return
        }
        
        // Check that we've got a valid, non-empty message
        guard let message = intent.content, !message.isEmpty else {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .siri, "Siri Intent completed with failure because there was no message (intent.content nil or empty).")
            }
            
            complete(code: .failure)
            
            return
        }
        
        let subject = String(message.prefix(Constants.subjectMaxLength))
        
        do {
            // Prepare the body
            let body = try Requests.prepareBody(
                fromText: config.fromText,
                message: message,
                subject: subject,
                token: token,
                platform: Constants.Platform.siri,
                attachments: []
            )
            
            // Send a boomerang request
            Requests.sendBoomerang(requestBody: body) { (result) in
                switch result {
                case .success:
                    if #available(iOS 12.0, *) {
                        os_log(.debug, log: .siri, "Siri Intent completed with success!")
                    }
                    
                    complete(code: .success)
                    
                case .failure(let error):
                    if #available(iOS 12.0, *) {
                        os_log(.error, log: .siri, "Siri Intent completed with failure. Boomerang request error: %{PUBLIC}@", error.localizedDescription)
                    }
                    
                    complete(code: .failure)
                }
            }
        } catch {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .siri, "Siri Intent completed with failure. Boomerang request error: %{PUBLIC}@", error.localizedDescription)
            }
            Requests.sendErrorLog(log: .emptyMessage, platform: Constants.Platform.siri, token: token, message: message, subject: subject, attachments: [])
            complete(code: .failure)
        }
        
    }
    
}
