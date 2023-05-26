////
////  SessionManagement+Extension.swift
////  Web3Auth
////
////  Created by Dhruv Jaiswal on 03/10/22.
////
//
//import CryptoSwift
//import Foundation
//import secp256k1
//
//extension SessionManagement {
//    func decryptData(privKeyHex: String, d: String) throws -> Web3AuthState {
//        let ecies = try encParamsHexToBuf(encParamsHex: d)
//        let result = try decrypt(privateKey: privKeyHex, opts: ecies)
//        guard let dict = try JSONSerialization.jsonObject(with: result.data(using: .utf8) ?? Data()) as? [String: Any],
//              let loginDetails = Web3AuthState(dict: dict, sessionID: privKeyHex) else { throw Web3AuthError.decodingError }
//        return loginDetails
//    }
//
//    func encryptData(privkeyHex: String, d: String) throws -> String {
//        guard let pubKey = SECP256K1.privateToPublic(privateKey: privkeyHex.hexa.data)?.web3.hexString.web3.noHexPrefix else {
//            throw Web3AuthError.runtimeError("Invalid private key hex")
//        }
//        let encParams = try encrypt(publicKey: pubKey, msg: d, opts: nil)
//        let data = try JSONEncoder().encode(encParams)
//        guard let string = String(data: data, encoding: .utf8) else { throw Web3AuthError.runtimeError("Invalid String from enc Params") }
//        return string
//    }
//
//    func encParamsBufToHex(encParamsHex: ECIES) throws -> ECIES {
//        guard let iv = encParamsHex.iv.web3.hexData?.web3.hexString,
//              let ephemPublicKey = encParamsHex.ephemPublicKey.web3.hexData?.toHexString(),
//              let ciphertext = encParamsHex.ciphertext.web3.hexData?.toHexString(),
//              let mac = encParamsHex.mac.web3.hexData?.web3.hexString else {
//            throw Web3AuthError.runtimeError("Invalid enc params")
//        }
//        return .init(iv: iv, ephemPublicKey: ephemPublicKey, ciphertext: ciphertext, mac: mac)
//    }
//
//    private func encParamsHexToBuf(encParamsHex: String) throws -> ECIES {
//        let data = encParamsHex.data(using: .utf8) ?? Data()
//        var arr = Array(repeating: "", count: 4)
//        do {
//            let dict = try JSONSerialization.jsonObject(with: data) as? [String: String]
//            dict?.forEach { key, value in
//                if key == "iv" {
//                    arr[0] = value
//                } else if key == "ephemPublicKey" {
//                    arr[1] = value
//                } else if key == "ciphertext" {
//                    arr[2] = value
//                } else if key == "mac" {
//                    arr[3] = value
//                }
//            }
//            return ECIES(iv: arr[0], ephemPublicKey: arr[1], ciphertext: arr[2], mac: arr[3])
//        } catch let error {
//            throw Web3AuthError.runtimeError(error.localizedDescription)
//        }
//    }
//
//    func encrypt(publicKey: String, msg: String, opts: ECIES?) throws -> ECIES {
//        guard let ephemPrivateKey = SECP256K1.generatePrivateKey(), let ephemPublicKey = SECP256K1.privateToPublic(privateKey: ephemPrivateKey)
//        else {
//            throw Web3AuthError.runtimeError("Private key generation failed")
//        }
//        let ephermalPublicKey = publicKey.strip04Prefix()
//        let ephermalPublicKeyBytes = ephermalPublicKey.hexa
//        var ephermOne = ephermalPublicKeyBytes.prefix(32)
//        var ephermTwo = ephermalPublicKeyBytes.suffix(32)
//        ephermOne.reverse(); ephermTwo.reverse()
//        ephermOne.append(contentsOf: ephermTwo)
//        let ephemPubKey = secp256k1_pubkey.init(data: array32toTuple(Array(ephermOne)))
//        guard
//            // Calculate g^a^b, i.e., Shared Key
//            //  let data = inprivateKey
//            let sharedSecret = SECP256K1.ecdh(pubKey: ephemPubKey, privateKey: ephemPrivateKey)
//        else {
//            throw Web3AuthError.runtimeError("ECDH error")
//        }
//
//        let sharedSecretData = sharedSecret.data
//        let sharedSecretPrefix = Array(tupleToArray(sharedSecretData).prefix(32))
//        let reversedSharedSecret = sharedSecretPrefix.uint8Reverse()
//        let hash = SHA2(variant: .sha512).calculate(for: Array(reversedSharedSecret))
//        let iv: [UInt8] = (opts?.iv ?? SECP256K1.randomBytes(length: 16)?.toHexString())?.hexa ?? []
//        let encryptionKey = Array(hash.prefix(32))
//        let macKey = Array(hash.suffix(32))
//        do {
//            // AES-CBCblock-256
//            let aes = try AES(key: encryptionKey, blockMode: CBC(iv: iv), padding: .pkcs7)
//            let encrypt = try aes.encrypt(msg.bytes)
//            let data = Data(encrypt)
//            let ciphertext = data
//            var dataToMac: [UInt8] = iv
//            dataToMac.append(contentsOf: [UInt8](ephemPublicKey.data))
//            dataToMac.append(contentsOf: [UInt8](ciphertext.data))
//            let mac = try? HMAC(key: macKey, variant: .sha2(.sha256)).authenticate(dataToMac)
//            return .init(iv: iv.toHexString(), ephemPublicKey: ephemPublicKey.toHexString(), ciphertext: ciphertext.toHexString(), mac: mac?.toHexString() ?? "")
//        } catch let err {
//            throw err
//        }
//    }
//
//    func decrypt(privateKey: String, opts: ECIES) throws -> String {
//        var result: String = ""
//        let ephermalPublicKey = opts.ephemPublicKey.strip04Prefix()
//        let ephermalPublicKeyBytes = ephermalPublicKey.hexa
//        var ephermOne = ephermalPublicKeyBytes.prefix(32)
//        var ephermTwo = ephermalPublicKeyBytes.suffix(32)
//        ephermOne.reverse(); ephermTwo.reverse()
//        ephermOne.append(contentsOf: ephermTwo)
//        let ephemPubKey = secp256k1_pubkey.init(data: array32toTuple(Array(ephermOne)))
//        guard
//            // Calculate g^a^b, i.e., Shared Key
//            let data = Data(hexString: privateKey),
//            let sharedSecret = SECP256K1.ecdh(pubKey: ephemPubKey, privateKey: data)
//        else {
//            throw Web3AuthError.runtimeError("ECDH Error")
//        }
//        let sharedSecretData = sharedSecret.data
//        let sharedSecretPrefix = tupleToArray(sharedSecretData).prefix(32)
//        let reversedSharedSecret = sharedSecretPrefix.reversed()
//        let iv = opts.iv.hexa
//        let newXValue = reversedSharedSecret.hexa
//        let hash = SHA2(variant: .sha512).calculate(for: newXValue.hexa).hexa
//        let AesEncryptionKey = hash.prefix(64)
//        do {
//            // AES-CBCblock-256
//            let aes = try AES(key: AesEncryptionKey.hexa, blockMode: CBC(iv: iv), padding: .pkcs7)
//            let decrypt = try aes.decrypt(opts.ciphertext.hexa)
//            let data = Data(decrypt)
//            result = String(data: data, encoding: .utf8) ?? ""
//        } catch let err {
//            throw err
//        }
//        return result
//    }
//}
