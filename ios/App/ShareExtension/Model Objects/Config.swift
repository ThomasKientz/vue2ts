//
//  Config.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 06/01/2020.
//

import Foundation
import JWTDecode

/// The subject mode defines if the Config should use its subject text or use the content to generate a subject.
enum SubjectMode {
    case custom
    case subjectText
    
    /// Init the subject mode from a string value. Typically from UserDefaults.
    static func fromUserDefaults(value: String?) -> SubjectMode {
        // We should use the subject text by default except if there's no value in SubjectMode or if it's explicitly marked "custom"
        switch value {
        case nil:
            return .custom
        case "custom":
            return .custom
        default:
            return .subjectText
        }
    }
}

struct EmailToken {
    
    let token: String
    
    let email: String
    
    init?(token: String) {
        self.token = token
        
        if let jwt = try? decode(jwt: token), let email = jwt.body["email"] as? String {
            self.email = email
        } else {
            return nil
        }
    }
    
}

/// An object that represents the app's config. Typically loaded from UserDefaults.
struct Config {
    
    // MARK: Properties
    
    let fromText: String
    
    let subjectMode: SubjectMode
    
    let subjectText: String
    
    let emailTokens: [EmailToken]
    
    
    
    // MARK: Helper Properties
    
    var hasAtLeastOneEmail: Bool {
        return !emailTokens.isEmpty
    }
    
    var hasMultipleEmails: Bool {
        return emailTokens.count > 1
    }
    
    
    
    // MARK: Life Cycle
    
    init(fromText: String?, subjectMode: SubjectMode, subjectText: String?, token1: String?, token2: String?) {
        self.fromText = fromText ?? "Boomerang"
        self.subjectMode = subjectMode
        
        // Set a default value to subject text if needed
        self.subjectText = subjectText ?? "New Boomerang"
        
        var tokens = [EmailToken]()
        
        if let token1 = token1, let newToken = EmailToken(token: token1) {
            tokens.append(newToken)
        }
        
        if let token2 = token2, let newToken = EmailToken(token: token2) {
            tokens.append(newToken)
        }
        
        self.emailTokens = tokens
    }
    
}
