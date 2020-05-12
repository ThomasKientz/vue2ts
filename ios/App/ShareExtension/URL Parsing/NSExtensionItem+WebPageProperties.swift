//
//  NSExtensionItem+WebPageProperties.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 11/05/2020.
//

import Foundation
import CoreServices

struct WebPageMetaData {
    let hostname: String
    let title: String
}

extension NSExtensionItem {
    
    func retrieveMetadata(_ completionHandler: @escaping (WebPageMetaData?) -> ()) {
        let propertyList = String(kUTTypePropertyList)
        
        guard let attachments = attachments else {
            completionHandler(nil)
            return
        }

        for attachment in attachments where attachment.hasItemConformingToTypeIdentifier(propertyList) {
            attachment.loadItem(
                forTypeIdentifier: propertyList,
                options: nil,
                completionHandler: { (item, error) -> Void in
                    guard let dictionary = item as? NSDictionary,
                        let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary,
                        let title = results["title"] as? String,
                        let hostname = results["hostname"] as? String else {
                            return
                    }

                    completionHandler(WebPageMetaData(hostname: hostname, title: title))
                }
            )
        }
        
        completionHandler(nil)
    }
    
}
