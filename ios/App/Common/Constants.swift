//
//  Constants.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 06/01/2020.
//

import Foundation

struct Constants {
    
    // MARK: Identifiers
    
    /// App Group Identifier
    static let appGroup = "group.settings.boomerang"
        
    /// Identifiers for the Platform field of a boomerang request
    struct Platform {
        /// Identifier to use in the Share Extension
        static let share = "ios_share"
        /// Identifier to use in the Siri Intents Extension
        static let siri = "ios_siri"
    }
    
    
    
    // MARK: API URL
    
//    #if DEBUG
//    /// URL for Debug Environment
//    static let apiBaseUrl = "https://boomerang-app-api-dev.herokuapp.com"
//    #else
//    /// URL for Production Environment
//    static let apiBaseUrl = "https://api.boomerang-app.io"
//    #endif
  
    static let apiBaseUrl = "https://api.boomerang-app.io"
    
    
    
    // MARK: Others…
    
    static let subjectMaxLength = 78
    
}
