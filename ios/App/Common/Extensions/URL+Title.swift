//
//  URL+Title.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 13/12/2019.
//

import Foundation
import SwiftSoup

extension URL {
    
    /// Get URL's html value and remove what stands before and after the title tag
    var title: String? {
        guard let html = try? String(contentsOf: self, encoding: .utf8),
            let doc: Document = try? SwiftSoup.parseBodyFragment(html) else {
                return nil
        }

        return try? doc.title()
    }
    
}
