//
//  SendError.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 16/12/2019.
//

import Foundation

enum SendError: Error {
    
    var localizedDescription: String {
        switch self {
        case .testRequestFailed:
            return "Servers are currently unavailable. Please try again later."
        case .individualFileInvalidSize:
            return "One of the uploaded attachments exceeds the maximum limit of 10MB."
        case .totalFileInvalidSize:
            return "The total size of the upload exceeds the maximum limit of 25MB."
        case .invalidFilesCount:
            return "The number of attachments exceeds the maximum limit of 10."
        case .sendRequestFailed:
            return "Something failed during the upload."
        }
    }
    
    case testRequestFailed
    
    case individualFileInvalidSize
    case totalFileInvalidSize
    case invalidFilesCount
    
    case sendRequestFailed
}

enum TestRequestError: Error {
    case invalidServerResponse
    case urlSessionError
}
