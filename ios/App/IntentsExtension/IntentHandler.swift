//
//  IntentHandler.swift
//  IntentsExtension
//
//  Created by Clément Cardonnel on 13/01/2020.
//

import Intents
import os.log

class IntentHandler: INExtension, INSendMessageIntentHandling {
    
    private let config = ConfigReader.loadConfig()
    
    
    
    override func handler(for intent: INIntent) -> Any? {
        switch intent {
        case is INSendMessageIntent, is INSetMessageAttributeIntent:
            return self
        default:
            return nil
        }
    }
    
    
    
    // MARK: - Resolving
    
    func resolveRecipients(for intent: INSendMessageIntent, with completion: @escaping ([INSendMessageRecipientResolutionResult]) -> Void) {
        if #available(iOS 12.0, *) {
            os_log(.info, log: .siri, "Resolving recipients…")
        }
        
        guard intent.recipients == nil
                || intent.recipients?.isEmpty ?? true
                || (intent.recipients?.count ?? 0) > 1 else {
            let firstRecipient = intent.recipients!.first!
            let response = [INSendMessageRecipientResolutionResult(personResolutionResult: INPersonResolutionResult.success(with: firstRecipient))]
            
            if #available(iOS 12.0, *) {
                os_log(.info, log: .siri, "Siri Intent recipient resolved: %{PRIVATE}@", firstRecipient)
            }
            
            completion(response)
            return
        }
        
        var persons = [INPerson]()
        
        for (index, token) in config.emailTokens.enumerated() {
            let handle = INPersonHandle(value: token.email, type: .emailAddress)
            let displayName = String(format: NSLocalizedString("EMAIL_NUMBERED", comment: ""), arguments: [(index + 1), token.email])
            
            let person: INPerson
            if #available(iOSApplicationExtension 12.0, *) {
                person = INPerson(
                    personHandle: handle,
                    nameComponents: nil,
                    displayName: displayName,
                    image: nil,
                    contactIdentifier: nil,
                    customIdentifier: token.token,
                    isMe: true)
            } else {
                person = INPerson(
                    personHandle: handle,
                    nameComponents: nil,
                    displayName: displayName,
                    image: nil,
                    contactIdentifier: nil,
                    customIdentifier: token.token)
            }
            
            persons.append(person)
        }
        
        if persons.count > 1 {
            if #available(iOS 12.0, *) {
                os_log(.info, log: .siri, "Siri Intent will attempt resolve recipients by disambiguation")
            }
            
            let response = [INSendMessageRecipientResolutionResult(personResolutionResult: INPersonResolutionResult.disambiguation(with: persons))]
            
            completion(response)
        } else if persons.count == 1 {
            let response = [INSendMessageRecipientResolutionResult(personResolutionResult: INPersonResolutionResult.success(with: persons.first!))]
            completion(response)
        } else {
            let response = [INSendMessageRecipientResolutionResult.unsupported()]
            completion(response)
        }
    }
    
    // Check that the intent contain a message
    func resolveContent(for intent: INSendMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let text = intent.content,
            !text.isEmpty {
            if #available(iOS 12.0, *) {
                os_log(.info, log: .siri, "Siri Intent content resolved: %{PRIVATE}@", text)
            }
            completion(INStringResolutionResult.success(with: text))
        }
        else {
            if #available(iOS 12.0, *) {
                os_log(.info, log: .siri, "Siri Intent attempting to resolve content by requesting value.")
            }
            completion(INStringResolutionResult.needsValue())
        }
    }
    
    
    
    // MARK: - Handle, execute
    
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
        
        
        // Check that we've got a valid token
        guard
            let recipient = intent.recipients?.first,
            let token = recipient.customIdentifier else {
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
    
    func confirm(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        let response = INSendMessageIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }
    
}



extension IntentHandler: INSetMessageAttributeIntentHandling {
    
    func handle(intent: INSetMessageAttributeIntent, completion: @escaping (INSetMessageAttributeIntentResponse) -> Void) {
        let userActivity = NSUserActivity(activityType: String(describing: INSetMessageAttributeIntent.self))
        
        completion(
            INSetMessageAttributeIntentResponse(
                code: INSetMessageAttributeIntentResponseCode.failure,
                userActivity: userActivity
            )
        )
    }
    
}
