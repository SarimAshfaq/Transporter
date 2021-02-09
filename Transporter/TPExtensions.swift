//
//  TPExtensions.swift
//  Example
//
//  Created by Le VanNghia on 3/26/15.
//  Copyright (c) 2015 Le VanNghia. All rights reserved.
//

import UIKit

extension UIDevice {
    private class var osVersion: String {
        return UIDevice.current.systemVersion
    }
    
    class func systemVersionEqualTo(version: String) -> Bool {
        return osVersion.compare(version, options: NSString.CompareOptions.numeric) == ComparisonResult.orderedSame
    }
    
    class func systemVersionGreaterThan(version: String) -> Bool {
        return osVersion.compare(version, options: NSString.CompareOptions.numeric) == ComparisonResult.orderedDescending
    }
    
    class func systemVersionGreaterThanOrEqualTo(version: String) -> Bool {
        return osVersion.compare(version, options: NSString.CompareOptions.numeric) != ComparisonResult.orderedAscending
    }
    
    class func systemVersionLessThan(version: String) -> Bool {
        return osVersion.compare(version, options: NSString.CompareOptions.numeric) == ComparisonResult.orderedAscending
    }
    
    class func systemVersionLessThanOrEqualTo(version: String) -> Bool {
        return osVersion.compare(version, options: NSString.CompareOptions.numeric) != ComparisonResult.orderedDescending
    }
}
