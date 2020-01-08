//
//  SendModel.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 16/12/2019.
//

import Foundation
import MobileCoreServices

enum UploadKind {
    case foreground, background
}

typealias SendingResult = ((Result<UploadKind,Error>) -> ())?

class SendModel {
    
    // MARK: Initialiazation-time Properties
    
    private let config: Config
    
    /// The completion handler that should be called to notify the view controller that this model has finished its job.
    private let onSendingCompleted: SendingResult
    
    private let attachments: [NSItemProvider]
    
    /// The queue in which `SendModel` shall operate.
    private let queue = DispatchQueue.global(qos: .background)
    
    // MARK: Properties for background
    
    /**
     The index of the token that we should use to send the email.
     It defaults to 0 in order to select the first emai, but it should be set by the view controller.
     */
    lazy var selectedTokenIndex: Int = 0
    
    /// We need to keep a reference to the background session to invalidate it at deinitialization time.
    private var backgroundSession: URLSession?
    
    private let sendSessionDelegate = SendSessionDelegate()
    
    // MARK: Properties used to process the request
            
    private var preparedAttachments = [Attachment]()
    
    /// A subject proceeded from a shared URL. This should be prioritized as the email subject.
    private var urlSubject: String?
    
    private var message: String?
    
    // MARK: Properties that are kinda methods but still are proprties
        
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
                self.onSendingCompleted?(.failure(BoomerangError.invalidSelection))
            }
        } else {
            // Case where we send a request with attachments. Other considerations are required.
            
            do {
                try RequestValidator(attachments: self.preparedAttachments).checkLimits()
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
                    self.onSendingCompleted?(.failure(BoomerangError.testRequestFailed))
                    break
                }
            }
        }
    })
    
    
    
    // MARK: Life Cycle
    
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
    
    
    
    // MARK: Helpers
    
    /// Process the attachments from weird and complex NSItemProvider to the more consise `Attachment` object.
    /// - Parameters:
    ///   - provider: The provider that actually contains the attachment we're sending, but which here only to infer additional informations.
    ///   - data: The data that came from the provider, but that should be extracted prior to this because it's very cumbersome to do.
    ///   - name: The name retrieved from the provider.
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
    
    
    
    // MARK: Networking
    
    /// Make a Send request that should trigger the boomerang.
    ///
    /// This method will decide if the request should happen in background or in foreground depending of the provided attachments.
    ///
    /// - Parameters:
    ///   - message: A message to add to the body of the boomerang.
    ///   - subject: The subject of the boomerang.
    ///   - attachments: Attachments to send with the boomerang.
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

        guard let url = URL(string: "\(Constants.apiBaseUrl)/send") else { return }
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
                    self.onSendingCompleted?(.failure(BoomerangError.sendRequestFailed))
                    return
                }
                
                let filePath = groupURL.appendingPathComponent("upload-attachment")
                try dataObject.write(to: filePath)
                task = self.backgroundSession!.uploadTask(with: request, fromFile: filePath)
            } else {
                request.httpBody = dataObject
                
                task = self.backgroundSession!.dataTask(with: request, completionHandler: { [unowned self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
                    if error == nil {
                        // Success
                        let statusCode = (response as! HTTPURLResponse).statusCode
                        print("Send request succeeded: HTTP \(statusCode)")
                        
                        if (200..<300).contains(statusCode) {
                            self.onSendingCompleted?(.success((.foreground)))
                        } else {
                            print(response.debugDescription)
                            self.onSendingCompleted?(.failure(self.handleServerError(
                                data: data,
                                defaultError: .sendRequestFailed
                            )))
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
                self.onSendingCompleted?(.success((.background)))
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
        
        guard let url = URL(string: "\(Constants.apiBaseUrl)/test") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        /* Start a new Task */
        let task = session.dataTask(with: request, completionHandler: { [unowned self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("Test request Succeeded: HTTP \(statusCode)")
                
                if (200..<300).contains(statusCode) {
                    completionHandler(.success(()))
                } else {
                    completionHandler(.failure(self.handleServerError(data: data, defaultError: .invalidServerResponse)))
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
    
    /// Look for an error message and return it as an error.
    /// - Parameter data: The data object returned by the URL Session response
    private func handleServerError(data: Data?, defaultError: BoomerangError) -> BoomerangError {
        if let data = data,
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:String],
            let message = json["message"] {
            return BoomerangError.server(message)
        } else {
            return defaultError
        }
    }
    
}
