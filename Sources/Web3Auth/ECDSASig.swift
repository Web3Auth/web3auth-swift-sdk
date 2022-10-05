//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 25/08/22.
//
import Foundation
#if SWIFT_PACKAGE
import secp256k1
#else
import secp256k1Swift
#endif 

extension secp256k1.Signing.ECDSASigner {
    public func signatureKeccaf256<D: Digest>(for digest: D) throws -> secp256k1.Signing.ECDSASignature {
        try signature(for: digest)
    }
    
    public func signatureKeccaf256Hash(for data: Data) throws -> secp256k1.Signing.ECDSASignature {
        try signatureKeccaf256(for: data.sha3(.keccak256))
    }
}

extension SECP256K1 {
    
    func sign(privkey: String, messageData: String) -> String {
        let privateBytes = privkey.hexa
        let privateKey = try! secp256k1.Signing.PrivateKey(rawRepresentation: privateBytes)
        //  Public key
        print(String(bytes: privateKey.publicKey.rawRepresentation))
        
        // ECDSA
        let messageData = messageData.data(using: .utf8)!
        let signature = try! privateKey.ecdsa.signatureKeccaf256Hash(for: messageData)
        
        return (try! signature.derRepresentation.toHexString())
    }
}
