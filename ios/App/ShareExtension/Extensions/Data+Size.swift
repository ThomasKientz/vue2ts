//
//  Data+Size.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 16/12/2019.
//

import Foundation

extension Data {
    
    /// The size of this data object in MB
    var sizeInMB: Double {
        return Double(count) / 1_000_000
    }
    
}
