//
//  Transaction.swift
//  Example
//
//  Created by Le VanNghia on 3/26/15.
//  Copyright (c) 2015 Le VanNghia. All rights reserved.
//

import Foundation

public class Transaction {
    private var firstTaskGroup: TPTaskGroup
    var currentTaskGroup: TPTaskGroup?
    
    public init(task: TPTransferTask) {
        firstTaskGroup = TPTaskGroup(task: task)
        currentTaskGroup = firstTaskGroup
    }
   
    public init(tasks: [TPTransferTask]) {
        firstTaskGroup = TPTaskGroup(tasks: tasks)
        currentTaskGroup = firstTaskGroup
    }
    
    public init(taskGroup: TPTaskGroup) {
        firstTaskGroup = taskGroup
        currentTaskGroup = firstTaskGroup
    }
    
    public func add(task: TPTransferTask) -> Self {
        let group = TPTaskGroup(task: task)
        currentTaskGroup?.next = group
        currentTaskGroup = group
        return self
    }
    
    public func add(tasks: [TPTransferTask]) -> Self {
        let group = TPTaskGroup(tasks: tasks)
        currentTaskGroup?.next = group
        currentTaskGroup = group
        return self
    }
   
    public func add(taskGroup: TPTaskGroup) -> Self {
        currentTaskGroup?.next = taskGroup
        currentTaskGroup = taskGroup
        return self
    }
}

extension Transaction {
    public func progress(handler: @escaping ProgressHandler) -> Self {
        currentTaskGroup?.progressHandler = handler
        return self
    }
    
    public func completed(handler: @escaping CompletionHandler) -> Self {
        currentTaskGroup?.completionHandler = handler
        return self
    }
    
    public func resume() {
        firstTaskGroup.resume()
    }
    
    public func validate() {
        
    }
}
