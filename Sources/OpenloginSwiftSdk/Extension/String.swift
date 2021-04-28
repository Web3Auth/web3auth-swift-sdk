//
//  File.swift
//  
//
//  Created by himanshu Chawla on 28/04/21.
//

import Foundation

public extension String {

    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func toBase64String() -> String {
        var result = Data(self.utf8).base64EncodedString()
        return result
    }
}


