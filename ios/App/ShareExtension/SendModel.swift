//
//  SendModel.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 16/12/2019.
//

import Foundation
import MobileCoreServices

typealias SendingResult = ((Result<Void,Error>) -> ())?

class SendModel {
    
    // MARK: - Properties
    
    var onSendingCompleted: SendingResult
    
    private let attachments: [NSItemProvider]
    
    
    private let queue = DispatchQueue.global(qos: .background)
        
    private var preparedAttachments = [Attachment]()
    
    private var message: String?
    
    private lazy var onitemsLoaded = DispatchWorkItem(block: { [weak self] in
        guard let self = self else { return }
        
        if self.preparedAttachments.isEmpty {
            // Case where we send a request without attachments
            
            self.send(
                message: self.message ?? "",
                subject: "test",
                attachments: self.preparedAttachments
            )
        } else {
            // Case where we send a request with attachments. Other considerations are required.
            
            let isIndividualSizeLimitReached = !self.preparedAttachments.isEmpty && (self.preparedAttachments.first(where: { $0.data.sizeInMB >= 10.0 }) != nil)
            if isIndividualSizeLimitReached {
                self.onSendingCompleted?(.failure(SendError.individualFileInvalidSize))
                return
            }
            
            let isTotalSizeLimitReached = (self.preparedAttachments.reduce(0) { $0 + $1.data.sizeInMB }) > 25.0
            if isTotalSizeLimitReached {
                self.onSendingCompleted?(.failure(SendError.totalFileInvalidSize))
                return
            }
            
            let filesCountLimitReached = self.preparedAttachments.count >= 10
            if filesCountLimitReached {
                self.onSendingCompleted?(.failure(SendError.invalidFilesCount))
                return
            }
            
            // Do a test request to check if the server is online
            self.testRequest { (result) in
                switch result {
                case .success:
                    // Looks ok, can proceed.
                    self.send(
                        message: self.message ?? "",
                        subject: "test",
                        attachments: self.preparedAttachments
                    )
                case .failure:
                    self.onSendingCompleted?(.failure(SendError.testRequestFailed))
                    break
                }
            }
        }
    })
    
    
    
    // MARK: - Life Cycle
    
    init(attachments: [NSItemProvider], onSendingCompleted: SendingResult) {
        self.onSendingCompleted = onSendingCompleted
        self.attachments = attachments
        
        start()
    }
    
    private func start() {
        let group = DispatchGroup()
        
        attachments.forEach { [unowned self] (provider) in
            
            queue.async(group: group) {
                group.enter()
                provider.loadItem(forTypeIdentifier: provider.registeredTypeIdentifiers.first!, options: nil) { (encoded, error) in
                    defer{ group.leave() }
                    
                    switch encoded {
                    case let data as Data:
                        if let attachment = self.attachment(for: provider, with: data) {
                            self.preparedAttachments.append(attachment)
                        }
                    case let url as URL where url.isFileURL:
                        if let data = try? Data(contentsOf: url),
                            let attachment = self.attachment(for: provider, with: data) {
                            self.preparedAttachments.append(attachment)
                        }
                    case let url as URL where !url.isFileURL:
                        if let title = url.title {
                            self.message = "\(title)\n\(url))"
                        } else {
                            self.message = url.absoluteString
                        }
                    case let text as String:
                        self.message = text
                    default:
                        //There may be other cases...
                        print("Unexpected data:", type(of: encoded))
                    }
                }
                
            }
            
        }
        
        group.notify(queue: queue, work: onitemsLoaded)
    }
    
    private func attachment(for provider: NSItemProvider, with data: Data) -> Attachment? {
        guard
            let mime = UTTypeCopyPreferredTagWithClass(provider.registeredTypeIdentifiers.first! as CFString, kUTTagClassMIMEType)?.takeRetainedValue() as String?
            else {
                return nil
        }
        
        print("Successfully retrieved data of UTI: \(provider.registeredTypeIdentifiers)")
        print("MIME is: \(mime)")
        
        return Attachment(
            name: provider.suggestedName ?? "Data",
            type: mime,
            data: data
        )
    }
    
    private func send(message: String, subject: String, attachments: [Attachment]) {
        
        let isBackgroundUpload = !attachments.isEmpty
        
        /* Configure session, choose between:
           * defaultSessionConfiguration
           * backgroundSessionConfigurationWithIdentifier:
         And set session-wide properties, such as: HTTPAdditionalHeaders,
         HTTPCookieAcceptPolicy, requestCachePolicy or timeoutIntervalForRequest.
         */
        let sessionConfig = isBackgroundUpload ? URLSessionConfiguration.background(withIdentifier: "com.boomerang.app.send-with-attachments") : URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 20.0

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
        let task: URLSessionDataTask
        if isBackgroundUpload {
            task = session.dataTask(with: request)
        } else {
            task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                if error == nil {
                    // Success
                    let statusCode = (response as! HTTPURLResponse).statusCode
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    
                    if (200..<300).contains(statusCode) {
                        self.onSendingCompleted?(.success(()))
                    } else {
                        self.onSendingCompleted?(.failure(SendError.sendRequestFailed))
                    }
                }
                else {
                    // Failure
                    print("URL Session Task Failed: %@", error!.localizedDescription);
                    if !isBackgroundUpload {
                        self.onSendingCompleted?(.failure(error!))
                    }
                }
            })
        }
        task.resume()
        session.finishTasksAndInvalidate()
        
        // If it's going to be a background upload, notify on success now.
        if isBackgroundUpload {
            self.onSendingCompleted?(.success(()))
        }
    }
    
    private func testRequest(_ completionHandler: @escaping (Result<Void,Error>) -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 5.0

        // Create session
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        guard let url = URL(string: "https://boomerang-app-api-dev.herokuapp.com/test") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        /* Start a new Task */
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URL Session Task Succeeded: HTTP \(statusCode)")
                
                if (200..<300).contains(statusCode) {
                    completionHandler(.success(()))
                } else {
                    completionHandler(.failure(TestRequestError.invalidServerResponse))
                }
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
                completionHandler(.failure(error!))
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    
}
