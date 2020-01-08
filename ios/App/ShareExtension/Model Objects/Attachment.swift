//
//  Attachment.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 13/12/2019.
//

import Foundation

struct Attachment {
    
    let name: String
    
    /// The MIME identifier of the attached data.
    let type: String
    
    let data: Data
    
    /**
     The dataUrl field as seen in the requests that this extension send.
     The goal of this property is to add a bit of necessery cruft to the base64 value.
     */
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
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case type = "type"
        case dataUrl = "dataUrl"
    }
    
}



extension Attachment: Encodable {
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(dataUrl, forKey: .dataUrl)
    }
    
}


extension Attachment: Decodable {
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        type = try values.decode(String.self, forKey: .type)
        
        let base64String = try values.decode(String.self, forKey: .dataUrl)
        if let data = Data(base64Encoded: base64String) {
            self.data = data
        } else {
            throw NSError()
        }
    }
    
}
