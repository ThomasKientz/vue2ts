//
//  ConfigReader.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 03/01/2020.
//

import Foundation

final class ConfigReader {
    
    static let defaults = UserDefaults(suiteName: Constants.appGroup)
    
    static func loadConfig() -> Config {
        let fromText = defaults?.string(forKey: "fromText")
        let subjectMode = defaults?.string(forKey: "subjectMode")
        let subjectText = defaults?.string(forKey: "subjectText")
        let token1 = defaults?.string(forKey: "token1")
        let token2 = defaults?.string(forKey: "token2")
        
        let config = Config(
            fromText: fromText,
            subjectMode: SubjectMode.fromUserDefaults(value: subjectMode),
            subjectText: subjectText,
            token1: token1,
            token2: token2
        )
        
        return config
    }
    
}
