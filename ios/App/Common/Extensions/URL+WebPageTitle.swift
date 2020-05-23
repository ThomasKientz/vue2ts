//
//  URL+WebPageTitle.swift
//  App
//
//  Created by Clément Cardonnel on 23/05/2020.
//

import Foundation
import SwiftSoup

extension URL {
    
    /// Get URL's html value and remove what stands before and after the title tag
    var webPageTitle: String? {
        guard let html = try? String(contentsOf: self, encoding: .utf8),
            let doc: Document = try? SwiftSoup.parseBodyFragment(html) else {
                return nil
        }

        return try? doc.title()
    }
    
}
