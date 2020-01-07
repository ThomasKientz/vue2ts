//
//  SendError.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 16/12/2019.
//

import Foundation

enum SendError: LocalizedError {
    
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
        }
    }
    
    case noValidEmail
        
    case individualFileInvalidSize
    case totalFileInvalidSize
    case invalidFilesCount
    case invalidSelection
    
    case sendRequestFailed
}

enum TestRequestError: Error {
    case invalidServerResponse
    case urlSessionError
}
