//
//  IntentHandler.swift
//  IntentsExtension
//
//  Created by Clément Cardonnel on 13/01/2020.
//

import Intents
import os.log

class IntentHandler: INExtension, INSendMessageIntentHandling {
    
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
        
        let userActivity = NSUserActivity(activityType: String(describing: INSendMessageIntent.self))
        
        let config = ConfigReader.loadConfig()
        guard config.hasAtLeastOneEmail else {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .siri, "Siri Intent completed with failure because no email was registered.")
            }
            
            completion(
                INSendMessageIntentResponse(
                    code: .failureRequiringAppLaunch,
                    userActivity: userActivity
                )
            )
            
            return
        }
        
        
        
    }
    
}
