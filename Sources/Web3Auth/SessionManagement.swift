//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 18/07/22.
//

import CryptoSwift
import Foundation
import secp256k1
import web3

public class SessionManagement {
    static let shared = SessionManagement()

    private init() {}
    private let storageServerUrl = "https://broadcast-server.tor.us"

    public func getActiveSession(sessionID: String) async throws -> Web3AuthState {
        let publicKeyHex = SECP256K1.privateToPublic(privateKey: sessionID.web3.hexData!, compressed: false)!.web3.hexString.web3.noHexPrefix
        let urlStr = "\(storageServerUrl)/store/get?key=\(publicKeyHex)"
        let url = URL(string: urlStr)!
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Web3AuthState, Error>) in
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard error == nil, let data = data else { return
                }
                do {
                    let msgDict = try JSONSerialization.jsonObject(with: data) as! [String: String]
                    let msgData = msgDict["message"]
                    let loginDetails = try self.decryptData(privKeyHex: sessionID, d: msgData ?? "")
                    continuation.resume(returning: loginDetails)
                } catch let err {
                    continuation.resume(throwing: err)
                }
            }.resume()
        })
    }
    

    private func decryptData(privKeyHex: String, d: String) throws -> Web3AuthState {
        let ecies = encParamsHexToBuf(encParamsHex: d)
        let result = try decrypt(privateKey: privKeyHex, opts: ecies)
        print(result)
        let dict = try JSONSerialization.jsonObject(with: result.data(using: .utf8)!) as! [String: Any]
        guard let loginDetails = Web3AuthState(dict: dict, sessionID: privKeyHex) else { throw Web3AuthError.unknownError }
        return loginDetails
    }

    private func encParamsHexToBuf(encParamsHex: String) -> Ecies {
        let data = encParamsHex.data(using: .utf8)!
        var arr = Array(repeating: "", count: 4)
        let dict = try! JSONSerialization.jsonObject(with: data) as! [String: String]
        dict.forEach { key, value in
            if key == "iv" {
                arr[0] = value
            } else if key == "ephemPublicKey" {
                arr[1] = value
            } else if key == "ciphertext" {
                arr[2] = value
            } else if key == "mac" {
                arr[3] = value
            }
        }
        return Ecies(iv: arr[0], ephemPublicKey: arr[1], ciphertext: arr[2], mac: arr[3])
    }

    private func decrypt(privateKey: String, opts: Ecies) throws -> String {
        var result: String = ""
        let ephermalPublicKey = opts.ephemPublicKey.strip04Prefix()
        let ephermalPublicKeyBytes = ephermalPublicKey.hexa
        var ephermOne = ephermalPublicKeyBytes.prefix(32)
        var ephermTwo = ephermalPublicKeyBytes.suffix(32)
        ephermOne.reverse(); ephermTwo.reverse()
        ephermOne.append(contentsOf: ephermTwo)
        let ephemPubKey = secp256k1_pubkey.init(data: array32toTuple(Array(ephermOne)))
        guard
            // Calculate g^a^b, i.e., Shared Key
            let data = Data(hexString: privateKey),
            let sharedSecret = SECP256K1.ecdh(pubKey: ephemPubKey, privateKey: data)
        else {
            throw Web3AuthError.unknownError
        }
        let sharedSecretData = sharedSecret.data
        let sharedSecretPrefix = tupleToArray(sharedSecretData).prefix(32)
        let reversedSharedSecret = sharedSecretPrefix.reversed()
        let iv = opts.iv.hexa
        let newXValue = reversedSharedSecret.hexa
        let hash = SHA2(variant: .sha512).calculate(for: newXValue.hexa).hexa
        let AesEncryptionKey = hash.prefix(64)
        do {
            // AES-CBCblock-256
            let aes = try AES(key: AesEncryptionKey.hexa, blockMode: CBC(iv: iv), padding: .pkcs7)
            let decrypt = try aes.decrypt(opts.ciphertext.hexa)
            let data = Data(decrypt)
            result = String(data: data, encoding: .utf8)!
        } catch let err {
            throw err
        }
        return result
    }
}


struct SessionLogutDataModel:Codable{
    var key:String
    var data:String
    var signature:String
    var timeout:Int
}
