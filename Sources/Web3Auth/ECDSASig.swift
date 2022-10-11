//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 25/08/22.
//
import Foundation
import secp256k1
//#if SWIFT_PACKAGE
//import secp256k1
//#else
//import secp256k1Swift
//#endif
//
//extension secp256k1.Signing.ECDSASigner {
//    public func signatureKeccaf256<D: Digest>(for digest: D) throws -> secp256k1.Signing.ECDSASignature {
//        try signature(for: digest)
//    }
//
//    public func signatureKeccaf256Hash(for data: Data) throws -> secp256k1.Signing.ECDSASignature {
//        try signatureKeccaf256(for: data.sha3(.keccak256))
//    }
//}

extension SECP256K1 {
    
    func sign(privkey: String, messageData: String) throws -> String {
        let encData = messageData.data(using: .utf8) ?? Data()
        let sig = SECP256K1.signForRecovery(hash: encData.sha3(.keccak256), privateKey: privkey.hexa.data)
        var vrs = SECP256K1.unmarshalSignature(signatureData: sig.rawSignature?.data ?? Data())
        let der = try SECP256K1.toDERReepresentaion(sig: sig.rawSignature?.data ?? Data())
        return der
    }
    
  public static func toDERReepresentaion(sig: Data) throws -> String {
        var result1 = "30"
        var result2 = ""
        var i = 68
        guard let umrashalsig = SECP256K1.unmarshalSignature(signatureData: sig)
        else { throw Web3AuthError.runtimeError("Invalid Signature") }
        result2.append("02")
        let revR = (umrashalsig.r.bytes).uint8Reverse()
        if revR[0] > 127 {
            result2.append(String(revR.count + 1, radix: 16))
            result2.append("00")
            i += 1
        } else {
            result2.append(String(revR.count, radix: 16))
        }

        let Rhex = revR.hexa.reversed().reversed()
        result2.append(Rhex)
        result2.append("02")
        let revS = (umrashalsig.s.bytes).uint8Reverse()
        let SHex = revS.hexa.reversed().reversed()
        if revS[0] > 127 {
            result2.append(String(revS.count + 1, radix: 16))
            result2.append("00")
            i += 1
        } else {
            result2.append(String(revS.count, radix: 16))
        }
        result2.append(SHex)
        result1.append(String(i, radix: 16))
        let result = result1 + result2
        return result
    }
}


