//
//  SendModel.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 16/12/2019.
//

import Foundation
import MobileCoreServices

class SendModel {
    
    // MARK: Initialiazation-time Properties
    
    private let config: Config
    
    /// The completion handler that should be called to notify the view controller that this model has finished its job.
    private let onSendingCompleted: SendingResult
    
    private let attachments: [NSItemProvider]
    
    /// The queue in which `SendModel` shall operate.
    private let queue = DispatchQueue.global(qos: .background)
    
    // MARK: Properties for background upload
    
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
        
    private lazy var onitemsLoaded = DispatchWorkItem(block: { [weak self] in
        guard let self = self else { return }
        
        if self.preparedAttachments.isEmpty {
            // Case where we send a request without attachments
            self.send()
        } else {
            // Case where we send a request with attachments. Other considerations are required.
            self.sendInBackground()
        }
    })
    
    
    
    // MARK: Life Cycle
    
    init(attachments: [NSItemProvider], config: Config, onSendingCompleted: @escaping SendingResult) {
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
    
    // MARK: Sending a boomerang
    
    /// Send a boomerang using local config and elements
    private func send() {
        guard let message = message else {
            onSendingCompleted(.failure(BoomerangError.invalidSelection))
            return
        }
        
        let subject: String
        
        if let urlSubject = urlSubject {
            subject = urlSubject
        } else if config.subjectMode == .subjectText {
            subject = config.subjectText
        } else {
            subject = String(message.prefix(78))
        }
        
        let body = Requests.prepareBody(
            fromText: config.fromText,
            message: message,
            subject: subject,
            token: config.emailTokens[selectedTokenIndex].token,
            platform: "ios_share_extension",
            attachments: preparedAttachments
        )
        
        Requests.sendBoomerang(requestBody: body, onSendingCompleted)
    }
    
    /// Send a boomerang in background using local config and elements
    private func sendInBackground() {
        do {
            try RequestValidator(attachments: preparedAttachments).checkLimits()
        } catch let error {
            onSendingCompleted(.failure(error))
            return
        }
        
        // Do a test request to check if the server is online
        Requests.testRequest { [weak self] (result) in
            guard let self = self else { return }
            
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
                
                let body = Requests.prepareBody(
                    fromText: self.config.fromText,
                    message: self.message ?? " ",
                    subject: subject,
                    token: self.config.emailTokens[self.selectedTokenIndex].token,
                    platform: Constants.platformShareExtension,
                    attachments: self.preparedAttachments
                )
                
                self.backgroundSession = Requests.sendBackgroundBoomerang(
                    requestBody: body,
                    delegate: self.sendSessionDelegate,
                    self.onSendingCompleted
                )
            case .failure:
                self.onSendingCompleted(.failure(BoomerangError.sendRequestFailed))
                break
            }
        }
    }
    
}
