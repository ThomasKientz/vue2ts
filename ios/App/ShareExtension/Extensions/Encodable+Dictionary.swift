//
//  Encodable+Dictionary.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 13/12/2019.
//
// Thanks to: https://stackoverflow.com/a/46329055/4802021

import Foundation

extension Encodable {
    
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
    
}
