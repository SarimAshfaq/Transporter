//
//  DownloadTask.swift
//  Example
//
//  Created by Le VanNghia on 3/26/15.
//  Copyright (c) 2015 Le VanNghia. All rights reserved.
//

import Foundation

public class DownloadTask : TPTransferTask {
    var task: URLSessionDownloadTask?
    var destination: NSURL
    var movingError: NSError?
    
    public init(url: String, destination: NSURL, params: [String: AnyObject]? = nil) {
        self.destination = destination
        super.init(url: url, params: params)
        method = .GET
    }
   
    override func setup() {
        super.setup()
        if let request = request {
            task = session?.downloadTask(with: request as URLRequest)
        }
    }
    
    public override func resume() {
        NSLog("[DownloadTask] did resume")
        task?.resume()
    }
}
