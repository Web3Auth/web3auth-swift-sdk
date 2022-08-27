//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 25/08/22.
//
import Foundation
import secp256k1

extension secp256k1.Signing.ECDSASigner {
    public func signatureKeccaf256<D: Digest>(for digest: D) throws -> secp256k1.Signing.ECDSASignature {
        try signature(for: digest)
    }
}
