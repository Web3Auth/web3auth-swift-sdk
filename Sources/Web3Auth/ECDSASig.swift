//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 25/08/22.
//
import BigInt
import Foundation
import curveSecp256k1

class SECP256K1 {
    static func sign(privkey: String, messageData: String) throws -> Signature {
        let encData = messageData.data(using: .utf8) ?? Data()
        let hash = try keccak256(data: encData)
        let sig = try curveSecp256k1.ECDSA.signRecoverable(key: SecretKey(hex: privkey), hash: hash.hexString)
        let sigData = try sig.serialize()
        let r = String(sigData.prefix(64))
        let s = String(sigData.suffix(66).prefix(64))
        return .init(r: r, s: s)
    }
}
