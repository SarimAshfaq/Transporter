//
//  UploadTask.swift
//  Example
//
//  Created by Le VanNghia on 3/26/15.
//  Copyright (c) 2015 Le VanNghia. All rights reserved.
//

import Foundation

public enum UploadDataType {
    case Data
    case File
    case Stream
}

public class UploadTask : TPTransferTask {
    var task: URLSessionUploadTask?
    var uploadDataType: UploadDataType = .File
    var file: NSURL?
    var data: NSData?
    var stream: InputStream?
    
    public override init(url: String, params: [String: AnyObject]? = nil) {
        super.init(url: url, params: params)
        method = .POST
    }
    
    public convenience init(url: String, data: NSData) {
        self.init(url: url)
        uploadDataType = .Data
        self.data = data
        totalBytes = Int64(data.length)
    }
    
    public convenience init(url: String, file: NSURL) {
        self.init(url: url)
        uploadDataType = .File
        self.file = file
        
        if let attr: NSDictionary = try? FileManager.default.attributesOfItem(atPath: file.path!) as NSDictionary {
            if error == nil {
                totalBytes = Int64(attr.fileSize())
            }
        }
    }
    
    public convenience init(url: String, stream: InputStream) {
        self.init(url: url)
        uploadDataType = .Stream
        self.stream = stream
    }
    
    override func setup() {
        super.setup()
        if let request = request {
            switch uploadDataType {
            case .File:
                if let file = self.file {
                    task = session?.uploadTask(with: request as URLRequest, fromFile: file as URL)
                }
            case .Data:
                task = session?.dataTask(with: request as URLRequest) as? URLSessionUploadTask
            case .Stream:
                task = session?.uploadTask(withStreamedRequest: request as URLRequest)
                break
            }
        }
    }
    
    public override func resume() {
        NSLog("[UploadTask] did resume")
        task?.resume()
    }
}
