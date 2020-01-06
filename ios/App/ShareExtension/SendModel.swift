//
//  SendModel.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 16/12/2019.
//

import Foundation
import MobileCoreServices
import os.log

typealias SendingResult = ((Result<Void,Error>) -> ())?

class SendModel {
    
    // MARK: - Properties
    
    private let config: Config
    
    lazy var selectedTokenIndex: Int = 0
    
    private let onSendingCompleted: SendingResult
    
    private let attachments: [NSItemProvider]
    
    private let sendSessionDelegate = SendSessionDelegate()
    
    private let queue = DispatchQueue.global(qos: .background)
        
    private var preparedAttachments = [Attachment]()
    
    /// A subject proceeded from a shared URL. This should be prioritized as the email subject.
    private var urlSubject: String?
    
    private var message: String?
    
    private var backgroundSession: URLSession?
    
    private lazy var onitemsLoaded = DispatchWorkItem(block: { [weak self] in
        guard let self = self else { return }
        
        if self.preparedAttachments.isEmpty {
            // Case where we send a request without attachments
            if let message = self.message {
                
                let subject: String
                
                if let urlSubject = self.urlSubject {
                    subject = urlSubject
                } else if self.config.subjectMode == .subjectText {
                    subject = self.config.subjectText
                } else {
                    subject = String(message.prefix(78))
                }
                
                self.send(
                    message: message,
                    subject: subject,
                    attachments: self.preparedAttachments
                )
            } else {
                self.onSendingCompleted?(.failure(SendError.invalidSelection))
            }
        } else {
            // Case where we send a request with attachments. Other considerations are required.
            
            do {
                try self.checkIndividualSizeLimit()
                try self.checkTotalSizeLimit()
                try self.checkFileCountLimit()
            } catch let error {
                self.onSendingCompleted?(.failure(error))
                return
            }
            
            // Do a test request to check if the server is online
            self.testRequest { (result) in
                switch result {
                case .success:
                    let subject: String
                    
                    if self.config.subjectMode == .subjectText {
                        subject = self.config.subjectText
                    } else if let message = self.message {
                        subject = String(message.prefix(78))
                    } else if !self.preparedAttachments.isEmpty {
                        subject = String(
                            self.preparedAttachments
                                .map({ $0.name })
                                .joined(separator: ", ")
                                .prefix(78)
                        )
                    } else {
                        subject = self.config.subjectText
                    }
                    
                    // Looks ok, can proceed.
                    self.send(
                        message: self.message ?? " ",
                        subject: subject,
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
    
    init(attachments: [NSItemProvider], config: Config, onSendingCompleted: SendingResult) {
        self.onSendingCompleted = onSendingCompleted
        self.attachments = attachments
        self.config = config
    }
    
    deinit {
        self.backgroundSession?.finishTasksAndInvalidate();
    }
    
    func start() {
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
                            let attachment = self.attachment(for: provider, with: data, name: url.lastPathComponent) {
                            self.preparedAttachments.append(attachment)
                        }
                    case let url as URL where !url.isFileURL:
                        if let title = url.title {
                            self.urlSubject = title
                            self.message = "\(title)\n\(url)"
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
    
    private func attachment(for provider: NSItemProvider, with data: Data, name: String? = nil) -> Attachment? {
        guard
            let mime = UTTypeCopyPreferredTagWithClass(provider.registeredTypeIdentifiers.first! as CFString, kUTTagClassMIMEType)?.takeRetainedValue() as String?
            else {
                return nil
        }
                
        print("Successfully retrieved data of UTI: \(provider.registeredTypeIdentifiers)")
        print("MIME is: \(mime)")
        
        return Attachment(
            name: name ?? provider.suggestedName ?? "Data",
            type: mime,
            data: data
        )
    }
    
    private func send(message: String, subject: String, attachments: [Attachment]) {
        
        let isBackgroundUpload = !attachments.isEmpty
        
        // Configure session
        let sessionConfig = isBackgroundUpload ? URLSessionConfiguration.background(withIdentifier: "com.boomerang.app.send-with-attachments") : URLSessionConfiguration.default
        sessionConfig.sharedContainerIdentifier = Constants.appGroup
        sessionConfig.timeoutIntervalForRequest = 20.0
        sessionConfig.isDiscretionary = false

        // Create Session
        backgroundSession = URLSession(
            configuration: sessionConfig,
            delegate: isBackgroundUpload ? sendSessionDelegate : nil,
            delegateQueue: nil
        )

        guard let url = URL(string: "https://api.boomerang-app.io/send") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Headers

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // JSON Body

        var bodyObject: [String : Any] = [
            "fromText": config.fromText,
            "message": message,
            "subject": subject,
            "token": config.emailTokens[selectedTokenIndex].token,
            "platform": "ios_share_extension"
        ]
        
        // Add the attachments if any
        if !attachments.isEmpty {
            bodyObject["attachments"] = attachments.compactMap({ $0.dictionary })
        }
        
        do {
            let dataObject = try JSONSerialization.data(withJSONObject: bodyObject, options: [])
             
            /* Start a new Task */
            let task: URLSessionTask
            if isBackgroundUpload {
                guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.settings.boomerang") else {
                    self.onSendingCompleted?(.failure(SendError.sendRequestFailed))
                    return
                }
                
                let filePath = groupURL.appendingPathComponent("upload-attachment")
                try dataObject.write(to: filePath)
                task = self.backgroundSession!.uploadTask(with: request, fromFile: filePath)
            } else {
                request.httpBody = dataObject
                
                task = self.backgroundSession!.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                    if error == nil {
                        // Success
                        let statusCode = (response as! HTTPURLResponse).statusCode
                        print("Send request succeeded: HTTP \(statusCode)")
                        
                        if (200..<300).contains(statusCode) {
                            self.onSendingCompleted?(.success(()))
                        } else {
                            print(response.debugDescription)
                            self.onSendingCompleted?(.failure(SendError.sendRequestFailed))
                        }
                    }
                    else {
                        // Failure
                        print("Send request failed: %@", error!.localizedDescription);
                        if !isBackgroundUpload {
                            self.onSendingCompleted?(.failure(error!))
                        }
                    }
                })
            }
            task.resume()
            
            // If it's going to be a background upload, notify on success now.
            if isBackgroundUpload {
                self.onSendingCompleted?(.success(()))
            }
            
        } catch {
            self.onSendingCompleted?(.failure(error))
        }
        
    }
    
    private func testRequest(_ completionHandler: @escaping (Result<Void,Error>) -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 5.0

        // Create session
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        guard let url = URL(string: "https://api.boomerang-app.io/test") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        /* Start a new Task */
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("Test request Succeeded: HTTP \(statusCode)")
                
                if (200..<300).contains(statusCode) {
                    completionHandler(.success(()))
                } else {
                    completionHandler(.failure(TestRequestError.invalidServerResponse))
                }
            }
            else {
                // Failure
                print("Test request failed: %@", error!.localizedDescription);
                completionHandler(.failure(error!))
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    
}



// MARK: - Limit Checks

private extension SendModel {
    
    func checkIndividualSizeLimit() throws {
        let individualSizeLimit = 10.0
        let itemAboveLimit = self.preparedAttachments.first(where: { $0.data.sizeInMB >= individualSizeLimit })
        
        if let itemAboveLimit = itemAboveLimit {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .itemDecoding, "Individual size of: %{PRIVATE}f MB exceeds limit of %{PUBLIC}f MB.", itemAboveLimit.data.sizeInMB, individualSizeLimit)
            }
            throw SendError.individualFileInvalidSize
        }
        
        if #available(iOS 12.0, *) {
            os_log(.debug, log: .itemDecoding, "Individual item size check passed with success. No item exceeded the %{PUBLIC}f MB limit.", individualSizeLimit)
        }
    }
    
    func checkTotalSizeLimit() throws {
        let totalSize = self.preparedAttachments.reduce(0) { $0 + $1.data.sizeInMB }
        let totalSizeLimit = 25.0
        let isTotalSizeLimitReached = totalSize > totalSizeLimit
        
        if isTotalSizeLimitReached {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .itemDecoding, "Total size of: %{PRIVATE}f MB exceeds limit of %{PUBLIC}f MB.", totalSize, totalSizeLimit)
            }
            throw SendError.totalFileInvalidSize
        }
        
        if #available(iOS 12.0, *) {
            os_log(.debug, log: .itemDecoding, "Total size check passed with success. (%{PRIVATE}f MB).", totalSize)
        }
    }
    
    func checkFileCountLimit() throws {
        let fileCountLimit = 10
        let fileCountLimitReached = self.preparedAttachments.count > fileCountLimit
        
        if fileCountLimitReached {
            if #available(iOS 12.0, *) {
                os_log(.error, log: .itemDecoding, "%{PRIVATE}d items exceeds limit of %{PUBLIC}d.", self.preparedAttachments.count, fileCountLimit)
            }
            throw SendError.invalidFilesCount
        }
        
        if #available(iOS 12.0, *) {
            os_log(.debug, log: .itemDecoding, "File count check passed with success. (%{PRIVATE}d items).", self.preparedAttachments.count)
        }
    }
    
}
