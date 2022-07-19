//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 18/07/22.
//

import Foundation
import web3
import CryptoSwift
import secp256k1

public class SessionManagement {
    static let shared = SessionManagement()

    private init() {}
    private let storageServerUrl = "https://broadcast-server.tor.us"
    


    public func getActiveSession(sessionID:String,completionHandler :@escaping (() -> Void)) {
        let publicKeyHex = SECP256K1.privateToPublic(privateKey: sessionID.web3.hexData!, compressed: false)!.web3.hexString.web3.noHexPrefix
        let urlStr = "\(storageServerUrl)/store/get?key=\(publicKeyHex)"
        let url = URL(string: urlStr)!
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else { return
            }
            let msgDict = try! JSONSerialization.jsonObject(with: data) as! [String:String]
            let msgData = (msgDict["message"] as! String)
            do{
                try self.decryptData(privKeyHex: sessionID, d: msgData)
            }
            catch{
                
            }
        }.resume()
        
    }
    
   private func decryptData(privKeyHex:String,d:String) throws{
        let ecies = encParamsHexToBuf(encParamsHex: d)
        let result = try decrypt(privateKey: privKeyHex, opts: ecies)
        print(result)
        let dict = try JSONSerialization.jsonObject(with: result.data(using: .utf8)!) as! [String:Any]
        guard let loginDetails = Web3AuthState(dict: dict, sessionID: privKeyHex) else{throw Web3AuthError.unknownError}
        print(loginDetails)
    }
    
   private func encParamsHexToBuf(encParamsHex:String) -> Ecies{
        let data = encParamsHex.data(using: .utf8)!
        var arr = Array(repeating: "", count: 4)
        let dict = try! JSONSerialization.jsonObject(with: data) as! [String:String]
        dict.forEach { key ,value in
            if key == "iv"{
               arr[0] = value
            }
            else if key == "ephemPublicKey"{
                arr[1] = value
            }
            else if key == "ciphertext"{
                arr[2] = value
            }
            else if key == "mac"{
                arr[3] = value
            }
        }
       return Ecies(iv: arr[0], ephemPublicKey: arr[1], ciphertext: arr[2], mac: arr[3])
        
    }
    
   private func decrypt(privateKey:String,opts:Ecies) throws -> String{
        var result:String = ""
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
            let sharedSecret = ecdh(pubKey: ephemPubKey, privateKey: data)
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







 let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
func ecdh(pubKey: secp256k1_pubkey, privateKey: Data) -> secp256k1_pubkey? {
    var localPubkey = pubKey // Pointer takes a variable
    if privateKey.count != 32 { return nil }
    let result = privateKey.withUnsafeBytes { (a: UnsafeRawBufferPointer) -> Int32? in
        if let pkRawPointer = a.baseAddress, let ctx = context, a.count > 0 {
            let privateKeyPointer = pkRawPointer.assumingMemoryBound(to: UInt8.self)
            let res = withUnsafeMutablePointer(to: &localPubkey) {
                secp256k1_ec_pubkey_tweak_mul(ctx, $0, privateKeyPointer)
            }
            return res
        } else {
            return nil
        }
    }
    guard let res = result, res != 0 else {
        return nil
    }
    return localPubkey
}

public func publicKeyToAddress(key: Data) -> Data {
    return key.web3.keccak256.suffix(20)
}


func tupleToArray(_ tuple: Any) -> [UInt8] {
    // var result = [UInt8]()
    let tupleMirror = Mirror(reflecting: tuple)
    let tupleElements = tupleMirror.children.map({ $0.value as! UInt8 })
    return tupleElements
}

func array32toTuple(_ arr: Array<UInt8>) -> (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
    return (arr[0] as UInt8, arr[1] as UInt8, arr[2] as UInt8, arr[3] as UInt8, arr[4] as UInt8, arr[5] as UInt8, arr[6] as UInt8, arr[7] as UInt8, arr[8] as UInt8, arr[9] as UInt8, arr[10] as UInt8, arr[11] as UInt8, arr[12] as UInt8, arr[13] as UInt8, arr[14] as UInt8, arr[15] as UInt8, arr[16] as UInt8, arr[17] as UInt8, arr[18] as UInt8, arr[19] as UInt8, arr[20] as UInt8, arr[21] as UInt8, arr[22] as UInt8, arr[23] as UInt8, arr[24] as UInt8, arr[25] as UInt8, arr[26] as UInt8, arr[27] as UInt8, arr[28] as UInt8, arr[29] as UInt8, arr[30] as UInt8, arr[31] as UInt8, arr[32] as UInt8, arr[33] as UInt8, arr[34] as UInt8, arr[35] as UInt8, arr[36] as UInt8, arr[37] as UInt8, arr[38] as UInt8, arr[39] as UInt8, arr[40] as UInt8, arr[41] as UInt8, arr[42] as UInt8, arr[43] as UInt8, arr[44] as UInt8, arr[45] as UInt8, arr[46] as UInt8, arr[47] as UInt8, arr[48] as UInt8, arr[49] as UInt8, arr[50] as UInt8, arr[51] as UInt8, arr[52] as UInt8, arr[53] as UInt8, arr[54] as UInt8, arr[55] as UInt8, arr[56] as UInt8, arr[57] as UInt8, arr[58] as UInt8, arr[59] as UInt8, arr[60] as UInt8, arr[61] as UInt8, arr[62] as UInt8, arr[63] as UInt8)
}
