//
//  NSExtensionItem+WebPageProperties.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 11/05/2020.
//
// Thanks to: https://diamantidis.github.io/2020/01/19/access-webpage-properties-from-ios-share-extension
// And also: https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html

import Foundation
import CoreServices

/// Various metadata extracted from ExtensionClass.js
struct WebPageMetaData {
    let hostname: String
    let title: String
    let url: String
}

extension NSExtensionItem {
    
    func retrieveMetadata(_ completionHandler: @escaping (WebPageMetaData?) -> ()) {
        let propertyList = String(kUTTypePropertyList)
        
        guard let attachments = attachments?.filter({ $0.hasItemConformingToTypeIdentifier(propertyList) }),
            !attachments.isEmpty else {
            completionHandler(nil)
            return
        }

        for attachment in attachments {
            attachment.loadItem(
                forTypeIdentifier: propertyList,
                options: nil,
                completionHandler: { (item, error) -> Void in
                    guard let dictionary = item as? NSDictionary,
                        let metadata = NSExtensionItem.webPageMetadata(from: dictionary) else {
                            completionHandler(nil)
                            return
                    }
                    
                    completionHandler(metadata)
                }
            )
        }
    }
    
    
    
    static func webPageMetadata(from dictionary: NSDictionary) -> WebPageMetaData? {
        guard let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary,
            let title = results["title"] as? String,
            let hostname = results["hostname"] as? String,
            let url = results["url"] as? String else {
                return nil
        }

        return WebPageMetaData(hostname: hostname, title: title, url: url)
    }
    
}
