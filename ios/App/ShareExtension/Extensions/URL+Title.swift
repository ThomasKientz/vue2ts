//
//  URL+Title.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 13/12/2019.
//

import Foundation

extension URL {
    
    /// Get URL's html value and remove what stands before and after the title tag
    var title: String? {
        /*
         Get the HTML from the URL, then proceed to isolate the title tag with ranges.
         
         `beginTitleRange`: Look for the `<title` tag, but ignore any character before the next `>` (end of tag).
         That helps us ignore parameters that may be installed inside the HTML title tag.
         */
        guard var title = try? String(contentsOf: self),
            let endTitleRange = title.range(of: "</title>"),
            let beginTitleRange = title.range(of: "<title.+?(?<=\\>)", options: .regularExpression)
            else { return nil }
        
        /*
         The order by which we reduce the string is important
         because starting by removing the first half will mess the range
         of the second half.
         */
        title.removeSubrange(endTitleRange.lowerBound ..< title.endIndex)
        title.removeSubrange(title.startIndex ..< beginTitleRange.upperBound)
        
        // Cleaning: Remove extra spaces that are sometimes in URLs
        title = title.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter {
            !$0.isEmpty
        }.joined(separator: " ")
        
        // Replace &quot; by ".
        title = title.replacingOccurrences(of: "&quot;", with: "\"")
        
        return title
    }
    
}
