//
//  BoomerangError.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 16/12/2019.
//

import Foundation

enum BoomerangError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case.noValidEmail:
            return "Couldn't find a valid email. Please open the app to register an email address."
        case .individualFileInvalidSize:
            return "One of the uploaded attachments exceeds the maximum limit of 10MB."
        case .totalFileInvalidSize:
            return "The total size of the upload exceeds the maximum limit of 25MB."
        case .invalidFilesCount:
            return "The number of attachments exceeds the maximum limit of 10."
        case .sendRequestFailed:
            return "Oops, an error occured. Please try again later."
        case .invalidSelection:
            return "The request couldn't be sent because the data wasn't of a supported format."
        case .invalidServerResponse:
            return "Servers are currently unavailable. Please try again later."
        case .urlSessionError:
            return "Something failed during the upload."
        case .server(let message):
            return message
        }
    }
    
    case noValidEmail
        
    case individualFileInvalidSize
    case totalFileInvalidSize
    case invalidFilesCount
    case invalidSelection
    
    case sendRequestFailed
    
    case invalidServerResponse
    case urlSessionError
    
    /// Server error with an error message attached
    case server(String)
}
