//
//  RequestValidator.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 08/01/2020.
//

import Foundation
import os.log

/**
 An object that checks if a set of attachments conform to the imposed limits.
 */
struct RequestValidator {
    
    // MARK: Implicitly initialized property
    
    /// The attachments to confronts limits to
    let attachments: [Attachment]
    
    
    
    // MARK: Using the validator
    
    /**
     Call this method to confront the attachments to the defined policy limits.
     
     Returns peacefully if limits are respected. But throws an error if one of them isn't.
     */
    func checkLimits() throws {
        try self.checkIndividualSizeLimit()
        try self.checkTotalSizeLimit()
        try self.checkFileCountLimit()
    }
    
}



// MARK: - Limit Checks

private extension RequestValidator {
    
    func checkIndividualSizeLimit() throws {
        let individualSizeLimit = 10.0
        let itemAboveLimit = attachments.first(where: { $0.data.sizeInMB >= individualSizeLimit })
        
        if let itemAboveLimit = itemAboveLimit {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .itemDecoding, "Individual size of: %{PRIVATE}f MB exceeds limit of %{PUBLIC}f MB.", itemAboveLimit.data.sizeInMB, individualSizeLimit)
            }
            throw BoomerangError.individualFileInvalidSize
        }
        
        if #available(iOS 12.0, *) {
            os_log(.debug, log: .itemDecoding, "Individual item size check passed with success. No item exceeded the %{PUBLIC}f MB limit.", individualSizeLimit)
        }
    }
    
    func checkTotalSizeLimit() throws {
        let totalSize = attachments.reduce(0) { $0 + $1.data.sizeInMB }
        let totalSizeLimit = 25.0
        let isTotalSizeLimitReached = totalSize > totalSizeLimit
        
        if isTotalSizeLimitReached {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .itemDecoding, "Total size of: %{PRIVATE}f MB exceeds limit of %{PUBLIC}f MB.", totalSize, totalSizeLimit)
            }
            throw BoomerangError.totalFileInvalidSize
        }
        
        if #available(iOS 12.0, *) {
            os_log(.debug, log: .itemDecoding, "Total size check passed with success. (%{PRIVATE}f MB).", totalSize)
        }
    }
    
    func checkFileCountLimit() throws {
        let fileCountLimit = 10
        let fileCountLimitReached = attachments.count > fileCountLimit
        
        if fileCountLimitReached {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .itemDecoding, "%{PRIVATE}d items exceeds limit of %{PUBLIC}d.", attachments.count, fileCountLimit)
            }
            throw BoomerangError.invalidFilesCount
        }
        
        if #available(iOS 12.0, *) {
            os_log(.debug, log: .itemDecoding, "File count check passed with success. (%{PRIVATE}d items).", attachments.count)
        }
    }
    
}
