//
//  TPTaskGroup.swift
//  Example
//
//  Created by Le VanNghia on 3/26/15.
//  Copyright (c) 2015 Le VanNghia. All rights reserved.
//

import Foundation
import UIKit

// TODO
/*
- group progress
- group completion handler
*/

public enum RunMode {
    case Concurrency
    case Serialization
}

public class TPTaskGroup : TPTask {
    public var completionHandler: CompletionHandler?
    
    var tasks: [TPTransferTask] = []
    var sessions: [URLSession] = []
    var mode: RunMode!
    var configured: Bool = false
    var next: TPTaskGroup?
    var curTaskIndex = 0
    var totalBytes: Int64 = 0
    var completedBytes: Int64 = 0
    
    private var sessionTasks: [URLSessionTask: TPTransferTask] = [:]
    
    public init(task: TPTransferTask) {
        super.init()
        mode = .Serialization
        tasks = [task]
    }
   
    public init(tasks: [TPTransferTask]) {
        super.init()
        mode = .Concurrency
        self.tasks = tasks
    }
    
    public init(left: TPTransferTask, right: TPTransferTask, mode: RunMode) {
        super.init()
        self.mode = mode
        tasks = [left, right]
    }
    
    public func append(task: TPTransferTask) -> Self {
        tasks.append(task)
        return self
    }
    
    override public func resume() {
        if !configured {
            switch mode! {
            case .Concurrency:
                let session = createSession()
                sessions = [session]
                for task in tasks {
                    task.session = session
                }
            case .Serialization:
                for task in tasks {
                    let session = createSession()
                    sessions.append(session)
                    task.session = session
                }
            }
            
            for task in tasks {
                task.setup()
                if let st = (task as? DownloadTask)?.task {
                    sessionTasks[st] = task
                } else if let st = (task as? UploadTask)?.task {
                    sessionTasks[st] = task
                }
            }
            totalBytes = tasks.reduce(0) { $0 + $1.totalBytes }
        }
       
        if mode == .Serialization {
            curTaskIndex = 0
            tasks[curTaskIndex].resume()
        } else {
            for task in tasks {
                task.resume()
            }
        }
    }
   
    public func completed(handler: @escaping CompletionHandler) -> Self {
        completionHandler = handler
        return self
    }
    
    private func createSession() -> URLSession {
        let identifier = NSUUID().uuidString
       
        var configuration: URLSessionConfiguration!
        
        if UIDevice.systemVersionGreaterThanOrEqualTo(version: "8.0") {
            configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        } else {
            configuration = URLSessionConfiguration.backgroundSessionConfiguration(identifier)
        }
        
        configuration.httpMaximumConnectionsPerHost = Transporter.HTTPMaximumconnectionsPerHost
        configuration.timeoutIntervalForRequest = Transporter.timeoutIntervalForRequest
        configuration.timeoutIntervalForResource = Transporter.timeoutIntervalForResource
        configuration.httpAdditionalHeaders = Transporter.headers
        
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }
}


extension TPTaskGroup : URLSessionDelegate {
    // All tasks enqueued have been delivered
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // check if all tasks have been completed
        session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            if dataTasks.isEmpty && uploadTasks.isEmpty && downloadTasks.isEmpty {
                Transporter.sessionDidFinishEventsForBackgroundURLSession(session: session)
            }
        }
    }
}


extension TPTaskGroup : URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let task = sessionTasks[dataTask] {
            task.responseData = data as NSData
        }
    }
}

extension TPTaskGroup : URLSessionTaskDelegate {
    // When any task completes
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        NSLog("[Session] a session task did complete with error : \(String(describing: error))")
        
        var curTask: TPTransferTask! = sessionTasks[task]
        if curTask == nil {
            return
        }
        curTask.error = error as NSError?
        curTask.isCompleted = true
            
        let httpResponse = task.response as? HTTPURLResponse
        let json: AnyObject? = curTask.jsonData
        curTask.completionHandler?(httpResponse, json, error as NSError?)
        
        // find the next task to resume
        switch mode! {
        case .Concurrency:
            let groupCompleted = tasks.filter { $0.isRunning }.isEmpty
            if groupCompleted {
                self.completionHandler?(tasks)
                next?.resume()
            }
        
        case .Serialization:
            curTaskIndex += 1
            if curTaskIndex < tasks.count && !curTask.failed {
                tasks[curTaskIndex].resume()
            } else {
                self.completionHandler?(tasks)
                next?.resume()
            }
        }
    }
    
    // Requests credentials from the delegate in response to an authentication request from the remote server
    /*
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    }
    */
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if let uploadTask = task as? URLSessionUploadTask {
            if let task = sessionTasks[uploadTask] {
                completedBytes += bytesSent
                task.progressHandler?(totalBytesSent, totalBytesExpectedToSend)
                self.progressHandler?(completedBytes, totalBytes)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        if let uploadTask = task as? URLSessionUploadTask {
            if let task = sessionTasks[uploadTask] as? UploadTask {
                completionHandler(task.stream!)
            }
        }
    }
}


extension TPTaskGroup : URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }
    
    //  The download task has resumed downloading
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
    }
    
    // Periodically informs the delegate about the download’s progress
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let task = sessionTasks[downloadTask] {
            completedBytes += bytesWritten
            task.progressHandler?(totalBytesWritten, totalBytesExpectedToWrite)
        }
    }
    
    // Download task completes successfully
    public func URLSession(session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        NSLog("[Session] Download finished : \(location)")
        if let task = sessionTasks[downloadTask] as? DownloadTask {
            try? FileManager.default.moveItem(at: location as URL, to: task.destination as URL)
        }
    }
}
