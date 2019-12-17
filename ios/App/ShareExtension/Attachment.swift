//
//  Attachment.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 13/12/2019.
//

import Foundation

struct Attachment: Codable {
    
    let name: String
    
    /// The MIME identifier of the attached data.
    let type: String
    
    let data: Data
    
    var dataUrl: String {
        return "data:\(type);base64,\(data.base64EncodedString())"
    }
    
    
    
    /// Initializes an attachment object in the correct format
    /// - Parameters:
    ///   - name: The name of the attachment. This ain't too big of a deal.
    ///   - type: Type should match the MIME identifier of the file that you're sending.
    ///   - data: The data object that is being attached. It will be converted in Base64 and appended with headers.
    init(name: String, type: String, data: Data) {
        self.name = name
        self.type = type
        self.data = data
    }
    
}
