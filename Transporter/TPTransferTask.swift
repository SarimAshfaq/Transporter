//
//  TPTransferTask.swift
//  Example
//
//  Created by Le VanNghia on 3/27/15.
//  Copyright (c) 2015 Le VanNghia. All rights reserved.
//

import Foundation

// TODO
/*
- header configuration
- parameter 
- resume
- suspend
- cancel
*/

public class TPTransferTask : TPTask {
    public var method: TPMethod = .GET
    public var HTTPShouldUsePipelining = false
    public var HTTPShouldHandleCookies = true
    public var allowsCellularAccess = true
    public var params: [String: AnyObject]?
    public var headers: [String: String]?
    public var completionHandler: TransferCompletionHandler?
    
    var url: String
    var request: NSMutableURLRequest?
    var totalBytes: Int64 = 0
    var session: URLSession?
    var responseData: NSData?
    var jsonData: AnyObject? {
        if let data = responseData {
            return try? JSONSerialization.data(withJSONObject: data, options: .fragmentsAllowed) as AnyObject
        }
        return nil
    }
    var error: NSError?
    var failed: Bool {
        return error != nil
    }
    
    public init(url: String, params: [String: AnyObject]? = nil) {
        self.url = url
        self.params = params
        super.init()
    }
   
    func setup() {
        let requestUrl = NSURL(string: url)!
        let request = NSMutableURLRequest(url: requestUrl as URL)
        request.httpMethod = method.rawValue
        request.httpShouldUsePipelining = HTTPShouldUsePipelining
        request.httpShouldHandleCookies = HTTPShouldHandleCookies
        request.allowsCellularAccess = allowsCellularAccess
        
        // append header
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        // append http body
        if let params = params {
            if method == .GET {
                let query = queryStringFromParams(params: params)
                let newUrl = url.appending("?\(query)")
                request.url = NSURL(string: newUrl) as URL?
            }
        }
        
        self.request = request
    }
    
    public func completed(handler: @escaping TransferCompletionHandler) -> Self {
        completionHandler = handler
        return self
    }
}
