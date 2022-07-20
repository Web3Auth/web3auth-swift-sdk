//
//  File.swift
//  
//
//  Created by Michael Lee on 8/3/2022.
//

import Foundation

extension String {
    
    func fromBase64URL() -> String? {
        var base64 = self
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64URL() -> String {
        var result = Data(self.utf8).base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }
}

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(utf8).base64EncodedString()
    }

    func strip04Prefix() -> String {
        if hasPrefix("04") {
            let indexStart = index(startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    func strip0xPrefix() -> String {
        if hasPrefix("0x") {
            let indexStart = index(startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    func addLeading0sForLength64() -> String {
        if count < 64 {
            let toAdd = String(repeating: "0", count: 64 - count)
            return toAdd + self
        } else {
            return self
        }
        // String(format: "%064d", self)
    }
}

extension StringProtocol {
    var hexa: [UInt8] {
        var startIndex = self.startIndex
        // print(startIndex, count)
        return (0 ..< count / 2).compactMap { _ in
            let endIndex = index(after: startIndex)
            defer { startIndex = index(after: endIndex) }
            // print(startIndex, endIndex)
            return UInt8(self[startIndex ... endIndex], radix: 16)
        }
    }
}

extension Sequence where Element == UInt8 {
    var data: Data { .init(self) }
    var hexa: String { map { .init(format: "%02x", $0) }.joined() }
}


