//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 06/12/2019.
//

import UIKit
import MobileCoreServices

class ShareViewController: UIViewController {

    @IBOutlet private weak var loaderVisualEffectView: UIVisualEffectView! {
        didSet {
            loaderVisualEffectView.layer.cornerRadius = 10
            loaderVisualEffectView.clipsToBounds = true
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem,
          let attachments = item.attachments
          else {
            return
        }
        
        let background = DispatchQueue.global(qos: .background)
        let group = DispatchGroup()
        
        var preparedAttachments = [Attachment]()
        var message: String?
        
        attachments.forEach { (provider) in
            
            background.async(group: group) {
                
                group.enter()
                provider.loadItem(forTypeIdentifier: provider.registeredTypeIdentifiers.first!, options: nil) { (encoded, error) in
                    defer{ group.leave() }
                    
                    let dataa: Data?
                    
                    switch encoded {
                    case let decodedData as Data:
                        dataa = decodedData
                    case let url as URL where url.isFileURL:
                        dataa = try? Data(contentsOf: url)
                    case let url as URL where !url.isFileURL:
                        if let title = url.title {
                            message = "\(title)\n\(url))"
                        } else {
                            message = url.absoluteString
                        }
                        
                        return
                    default:
                        dataa = nil
                        //There may be other cases...
                        print("Unexpected data:", type(of: encoded))
                    }
                    
                    let mimee = UTTypeCopyPreferredTagWithClass(provider.registeredTypeIdentifiers.first! as CFString, kUTTagClassMIMEType)?.takeRetainedValue() as String?
                    guard let data = dataa, let mime = mimee else {
                        return
                    }
                    
                    print("Successfully retrieved data of UTI: \(provider.registeredTypeIdentifiers)")
                    print("MIME is: \(mime)")
                    
                    preparedAttachments.append(
                        Attachment(
                            name: provider.suggestedName ?? "Data",
                            type: mime,
                            data: data
                        )
                    )
                }
                
            }
            
        }
        
        group.notify(queue: background) { [weak self] in
            self?.send(
                message: message ?? "",
                subject: "test",
                attachments: preparedAttachments
            )
        }
    }
    
    
    
    func send(message: String, subject: String, attachments: [Attachment]) {
        
        /* Configure session, choose between:
           * defaultSessionConfiguration
           * ephemeralSessionConfiguration
           * backgroundSessionConfigurationWithIdentifier:
         And set session-wide properties, such as: HTTPAdditionalHeaders,
         HTTPCookieAcceptPolicy, requestCachePolicy or timeoutIntervalForRequest.
         */
        let sessionConfig = URLSessionConfiguration.default

        /* Create session, and optionally set a URLSessionDelegate. */
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        /* Create the Request:
           Send  (POST https://boomerang-app-api-dev.herokuapp.com/send)
         */

        guard let url = URL(string: "https://boomerang-app-api-dev.herokuapp.com/send") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Headers

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // JSON Body

        let bodyObject: [String : Any] = [
            "fromText": "Boomerang",
            "message": message,
            "subject": subject,
            "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlc3RAZG9tYWluLmNvbSIsImlhdCI6MTU3NDY5ODE5NX0.KLAcendFFzP7OI7GlFCTu-LyV3ut9uZmBP0thBb2RZY",
            "attachments": attachments.compactMap({ $0.dictionary })
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])

        /* Start a new Task */
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URL Session Task Succeeded: HTTP \(statusCode)")
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
}
