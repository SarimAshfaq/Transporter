//
//  TPCommon.swift
//  Example
//
//  Created by Le VanNghia on 3/26/15.
//  Copyright (c) 2015 Le VanNghia. All rights reserved.
//

import Foundation

// TODO
/*
- completionHander
    - uploading
    - downloading
    - group
*/

public enum TPMethod : String {
    case GET    = "GET"
    case POST   = "POST"
    case PUT    = "PUT"
}

public typealias ProgressHandler = (_ completedBytes: Int64, _ totalBytes: Int64) -> ()
public typealias CompletionHandler = (_ tasks: [TPTransferTask]) -> ()
public typealias TransferCompletionHandler = (_ response: HTTPURLResponse?, _ json: AnyObject?, _ error: NSError?) -> ()

precedencegroup ToPrecedence {
    associativity: left
    higherThan: AdditionPrecedence
}
infix operator --> : ToPrecedence

public func --> (left: TPTransferTask, right: TPTransferTask) -> TPTaskGroup {
    return TPTaskGroup(left: left, right: right, mode: .Serialization)
}

public func --> (left: TPTaskGroup, right: TPTransferTask) -> TPTaskGroup {
    return left.append(task: right)
}

infix operator ||| : ToPrecedence

public func ||| (left: TPTransferTask, right: TPTransferTask) -> TPTaskGroup {
    return TPTaskGroup(left: left, right: right, mode: .Concurrency)
}

public func ||| (left: TPTaskGroup, right: TPTransferTask) -> TPTaskGroup {
    return left.append(task: right)
}

// http boby builder
func queryStringFromParams(params: [String: AnyObject]) -> String {
    let paramsArray = convertParamsToArray(params: params)
    var queryString = paramsArray.map{ "\($0)=\($1)" }.joined(separator: "&")//join("&", paramsArray.map{ "\($0)=\($1)" })
    
    return queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
}

func convertParamsToArray(params: [String: AnyObject]) -> [(String, AnyObject)] {
    var result = [(String, AnyObject)]()
    
    for (key, value) in params {
        if let arrayValue = value as? NSArray {
            for nestedValue in arrayValue {
                let dic = ["\(key)[]": nestedValue as AnyObject]
                result += convertParamsToArray(params: dic)
            }
        }
        else if let dicValue = value as? NSDictionary {
            for (nestedKey, nestedValue) in dicValue {
                let dic = ["\(key)[\(nestedKey)]": nestedValue as AnyObject]
                result += convertParamsToArray(params: dic)
            }
        }
        else {
            result.append(("\(key)", value))
        }
    }
    
    return result
}
