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
import CryptoKit

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
                    let msgDict = try JSONSerialization.jsonObject(with: data) as? [String: String]
                    let msgData = msgDict?["message"]
                    let loginDetails = try self.decryptData(privKeyHex: sessionID, d: msgData ?? "")
                    continuation.resume(returning: loginDetails)
                } catch let err {
                    continuation.resume(throwing: err)
                }
            }.resume()
        })
    }
    
    public func logout(sessionID: String) async throws -> Bool {
        do {
            let privKey = sessionID.hexa
            let publicKeyHex = SECP256K1.privateToPublic(privateKey: privKey.data, compressed: false)!.web3.hexString.web3.noHexPrefix
            let encData = try encryptData(privkeyHex: sessionID, d: "")
            let sig = SECP256K1().sign(privkey: privKey.toHexString(), messageData: encData)
            let urlStr = "\(storageServerUrl)/store/set"
            let data = SessionLogutDataModel(key: publicKeyHex, data: encData, signature: sig, timeout: 1)
            let encodedData = try JSONEncoder().encode(data)
            var req = URLRequest(url: URL(string: urlStr)!)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = encodedData
            return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Bool, Error>) in
            URLSession.shared.dataTask(with: req) { data, _, error in
                guard error == nil, let data = data else { return
                }
                do {
                    let msgDict = try JSONSerialization.jsonObject(with: data)
                    print(msgDict)
                       continuation.resume(returning: true)
                } catch let err {
                       continuation.resume(throwing: err)
                }
            }.resume()
        })
        }
        catch {
            throw Web3AuthError.appCancelled
        }
    }
    
    func decryptData(privKeyHex: String, d: String) throws -> Web3AuthState {
        let ecies = encParamsHexToBuf(encParamsHex: d)
        let result = try decrypt(privateKey: privKeyHex, opts: ecies)
        print(result)
        let dict = try JSONSerialization.jsonObject(with: result.data(using: .utf8)!) as! [String: Any]
        guard let loginDetails = Web3AuthState(dict: dict, sessionID: privKeyHex) else { throw Web3AuthError.unknownError }
        return loginDetails
    }
    
    func encryptData(privkeyHex: String, d: String) throws -> String {
        // let json = try JSONSerialization.jsonObject(with: d.data(using: .utf8)!)
        guard let pubKey = SECP256K1.privateToPublic(privateKey: privkeyHex.hexa.data)?.web3.hexString.web3.noHexPrefix else {
            throw Web3AuthError.unknownError
        }
        let encParams = try encrypt(publicKey: pubKey, msg: "", opts: nil)
        // let jsonString = try JSONSerialization.jsonObject(with: jsonData) as! String
        //  let encParamsHex = encParamsBufToHex(encParamsHex: encParams)
        let data = try JSONEncoder().encode(encParams)
        let string = String(data: data, encoding: .utf8)!
        return string
    }
    
    private func encParamsBufToHex(encParamsHex: Ecies) -> Ecies {
        return .init(iv: encParamsHex.iv.web3.hexData?.web3.hexString ?? "", ephemPublicKey: encParamsHex.ephemPublicKey.web3.hexData?.toHexString() ?? "", ciphertext: encParamsHex.ciphertext.web3.hexData?.toHexString() ?? "", mac: encParamsHex.mac.web3.hexData?.web3.hexString ?? "")
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
    
    func encrypt(publicKey: String, msg: String, opts: Ecies?) throws -> Ecies {
        let ephemPrivateKey = SECP256K1.generatePrivateKey()!
        //   let ephemPrivateKey = "cd50e9988c97b90c9b1bf537ab5be74116a59fc935a91c8ae80b029161d1d4b4".web3.hexData!
        let ephemPublicKey = SECP256K1.privateToPublic(privateKey: ephemPrivateKey)!
        let ephermalPublicKey = publicKey.strip04Prefix()
        let ephermalPublicKeyBytes = ephermalPublicKey.hexa
        var ephermOne = ephermalPublicKeyBytes.prefix(32)
        var ephermTwo = ephermalPublicKeyBytes.suffix(32)
        ephermOne.reverse(); ephermTwo.reverse()
        ephermOne.append(contentsOf: ephermTwo)
        let ephemPubKey = secp256k1_pubkey.init(data:array32toTuple(Array(ephermOne)))
        guard
            // Calculate g^a^b, i.e., Shared Key
            //  let data = inprivateKey
            let sharedSecret = SECP256K1.ecdh(pubKey: ephemPubKey, privateKey: ephemPrivateKey)
        else {
            throw Web3AuthError.unknownError
        }
        
        let sharedSecretData = sharedSecret.data
        let sharedSecretPrefix = Array(tupleToArray(sharedSecretData).prefix(32))
        let reversedSharedSecret = sharedSecretPrefix.uint8Reverse()
        let hash = SHA2(variant: .sha512).calculate(for: Array(reversedSharedSecret))
        let iv = (opts?.iv ?? SECP256K1.randomBytes(length: 16)!.toHexString()).hexa
        // let iv:[UInt8] = [125, 33, 242, 59, 245, 142, 229, 101, 58, 133, 37, 187, 132, 178, 241, 127]
        let encryptionKey = Array(hash.prefix(32))
        let macKey = Array(hash.suffix(32))
        do {
            // AES-CBCblock-256
            let aes = try AES(key: encryptionKey, blockMode: CBC(iv: iv),padding:.pkcs7)
            let encrypt = try aes.encrypt([116, 111, 32, 97])
            let data = Data(encrypt)
            let ciphertext = data
            var dataToMac: [UInt8] = iv
            dataToMac.append(contentsOf: [UInt8](ephemPublicKey.data))
            dataToMac.append(contentsOf: [UInt8](ciphertext.data))
            let mac = try? HMAC(key: macKey, variant: .sha2(.sha256)).authenticate(dataToMac)
            return .init(iv: iv.toHexString(), ephemPublicKey: ephemPublicKey.toHexString(), ciphertext: ciphertext.toHexString(), mac: mac!.toHexString())
        } catch let err {
            throw err
        }
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



