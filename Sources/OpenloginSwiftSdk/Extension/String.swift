//
//  File.swift
//  
//
//  Created by himanshu Chawla on 28/04/21.
//

import Foundation

public extension String {

    var parametersFromQueryString: [String: String] {
         return dictionaryBySplitting("&", keyValueSeparator: "=")
     }
    
    func dictionaryBySplitting(_ elementSeparator: String, keyValueSeparator: String) -> [String: String] {
        var string = self
        

        if hasPrefix(elementSeparator) {
            string = String(dropFirst(1))
        }

        var parameters = [String: String]()

        let scanner = Scanner(string: string)

        while !scanner.isAtEnd {
            var key: NSString?
            scanner.scanUpTo(keyValueSeparator, into: &key)
            scanner.scanString(keyValueSeparator, into: nil)

            var value: NSString?
            scanner.scanUpTo(elementSeparator, into: &value)
            scanner.scanString(elementSeparator, into: nil)
            if let key = key as String? {
                if let value = value as String? {
                    if key.contains(elementSeparator) {
                        var keys = key.components(separatedBy: elementSeparator)
                        if let key = keys.popLast() {
                            parameters.updateValue(value, forKey: String(key))
                        }
                        for flag in keys {
                            parameters.updateValue("", forKey: flag)
                        }
                    } else {
                        parameters.updateValue(value, forKey: key)
                    }
                } else {
                    parameters.updateValue("", forKey: key)
                }
            }
        }

        return parameters
    }
    
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func toBase64String() -> String {
        let result = Data(self.utf8).base64EncodedString()
        return result
    }
}


