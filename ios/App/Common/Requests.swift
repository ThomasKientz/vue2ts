//
//  Requests.swift
//  IntentsExtension
//
//  Created by Clément Cardonnel on 13/01/2020.
//

import Foundation

enum UploadKind {
    case foreground, background
}

typealias SendingResult = ((Result<UploadKind,Error>) -> ())

struct Requests {
    
    /// Prepare a HTTP body for a Boomerang send request.
    static func prepareBody(fromText: String, message: String, subject: String, token: String, platform: String, attachments: [Attachment]) throws -> [String: Any] {
        /*
         Enforce that either the message or the attachments are not empty.
         There must be some content to send!
         */
        guard !message.isEmpty || !attachments.isEmpty else {
            throw BoomerangError.emptyContent
        }
        
        var bodyObject: [String : Any] = [
            "fromText": fromText,
            "message": message,
            "subject": subject,
            "token": token,
            "platform": platform
        ]
        
        // Add the attachments if any
        if !attachments.isEmpty {
            bodyObject["attachments"] = attachments.compactMap({ $0.dictionary })
        }
        
        return bodyObject
    }
    
    /// Send a boomerang
    /// - Parameters:
    ///   - requestBody: The http body that describes the boomerang.
    ///   - completionHandler: A completion handler invoked at the end of the process.
    static func sendBoomerang(requestBody: [String: Any], _ completionHandler: @escaping SendingResult) {
        guard let url = URL(string: "\(Constants.apiBaseUrl)/send") else {
            completionHandler(.failure(BoomerangError.sendRequestFailed))
            return
        }
        
        // Session
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        // Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Adding the http body
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completionHandler(.failure(error))
        }
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("Send request succeeded: HTTP \(statusCode)")
                
                if (200..<300).contains(statusCode) {
                    // Success
                    completionHandler(.success(.foreground))
                } else {
                    // Failure
                    print(response.debugDescription)
                    completionHandler(.failure(handleServerError(
                        data: data,
                        defaultError: .sendRequestFailed
                    )))
                }
            }
            else {
                // Failure
                print("Send request failed: %@", error!.localizedDescription);
                completionHandler(.failure(error!))
            }
        })
        
        task.resume()
    }
    
    /// Send a boomerang in background
    ///
    /// Returns an URLSession that should be handled and finished when needed.
    ///
    /// - Parameters:
    ///   - requestBody: The http body that describes the boomerang.
    ///   - sendSessionDelegate: The delegate that takes care of receiving the response to the background request
    ///   - completionHandler: A completion handler invoked at the end of the process.
    static func sendBackgroundBoomerang(requestBody: [String: Any], delegate sendSessionDelegate: SendSessionDelegate, _ completionHandler: SendingResult) -> URLSession? {
        guard let url = URL(string: "\(Constants.apiBaseUrl)/send") else {
            completionHandler(.failure(BoomerangError.sendRequestFailed))
            return nil
        }
        
        // Session Config
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: "com.boomerang.app.send-with-attachments")
        // This is very important to prevent error -995 (https://stackoverflow.com/a/26319143/4802021)
        sessionConfig.sharedContainerIdentifier = Constants.appGroup
        /* Ideally, we'd want to set this property as true,
         but in order to guarantee the fastest experience possible,
         we'll mark it as false. */
        sessionConfig.isDiscretionary = true
        
        // Session
        let session = URLSession(
            configuration: sessionConfig,
            delegate: sendSessionDelegate,
            delegateQueue: nil
        )
        
        // Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Adding the http body
            let dataObject = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = dataObject
            
            guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroup) else {
                completionHandler(.failure(BoomerangError.sendRequestFailed))
                return nil
            }
            
            let filePath = groupURL.appendingPathComponent("upload-attachment")
            try dataObject.write(to: filePath)
            
            let task = session.uploadTask(with: request, fromFile: filePath)
            
            task.resume()
            
            // We send a success message to let the flow continue
            completionHandler(.success(.background))
        } catch {
            completionHandler(.failure(error))
        }
        
        return session
    }
    
    /// Send a test request to check if the back-end is operational
    /// - Parameter completionHandler: A completion handler telling if the back-end is operational (success) or not (failure)
    static func testRequest(_ completionHandler: @escaping (Result<Void,Error>) -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 5.0

        // Create session
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        guard let url = URL(string: "\(Constants.apiBaseUrl)/test") else { return }
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
    private static func handleServerError(data: Data?, defaultError: BoomerangError) -> BoomerangError {
        if let data = data,
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:String],
            let message = json["message"] {
            return BoomerangError.server(message)
        } else {
            return defaultError
        }
    }
    
}
