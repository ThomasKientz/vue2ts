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
    /// The subject will be defined by the user preferences. The user registered a custom subject in the main app and it's this subject that we're going to set in every case.
    case userPreference
    /// The subject will be defined by the content being shared. It will ignore potential custom subject field and will try to infer the subject from text, URL, or file data.
    case contentInferred
    
    /// Init the subject mode from a string value. Typically from UserDefaults.
    static func fromUserDefaults(value: String?) -> SubjectMode {
        // We should use the subject text by default except if there's no value in SubjectMode or if it's explicitly marked "custom"
        switch value {
        case "custom":
            return .userPreference
        case "preview":
            return .contentInferred
        case nil:
            // No preference set, we'll use the content
            return .contentInferred
        default:
            // No preference set, we'll use the content
            return .contentInferred
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
