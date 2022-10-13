//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 18/07/22.
//

import BigInt
import Foundation
import OSLog
import web3

public class SessionManagement {
    static let shared = SessionManagement()
    private init() {}
    private let storageServerUrl = "https://broadcast-server.tor.us"

    func getActiveSession(sessionID: String) async throws -> Web3AuthState {
        guard let publicKeyHex = SECP256K1.privateToPublic(privateKey: sessionID.hexa.data, compressed: false)?.web3.hexString.web3.noHexPrefix else { throw Web3AuthError.runtimeError("Invalid Session ID") }
        let urlStr = "\(storageServerUrl)/store/get?key=\(publicKeyHex)"
        let url = URL(string: urlStr)!
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Web3AuthState, Error>) in
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil, let data = data, let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else { return
                    continuation.resume(throwing: error ?? Web3AuthError.unknownError)
                }
                do {
                    let msgDict = try JSONSerialization.jsonObject(with: data) as? [String: String]
                    let msgData = msgDict?["message"] // "Invalid public key"
                    let loginDetails = try self.decryptData(privKeyHex: sessionID, d: msgData ?? "")
                    continuation.resume(returning: loginDetails)
                } catch let err {
                    continuation.resume(throwing: err)
                }
            }.resume()
        })
    }

    func logout(sessionID: String) async throws {
        do {
            let privKey = sessionID.hexa
            guard let publicKeyHex = SECP256K1.privateToPublic(privateKey: sessionID.hexa.data, compressed: false)?.web3.hexString.web3.noHexPrefix else { throw Web3AuthError.runtimeError("Invalid Session ID") }
            let encData = try encryptData(privkeyHex: sessionID, d: "")
            let sig = try SECP256K1().sign(privkey: privKey.toHexString(), messageData: encData)
            let urlStr = "\(storageServerUrl)/store/set"
            let sigData = try JSONEncoder().encode(sig)
            let sigJsonStr = String(data: sigData, encoding: .utf8) ?? ""
            let data = SessionLogoutDataModel(key: publicKeyHex, data: encData, signature: sigJsonStr, timeout: 1)
            print(data)
            let encodedData = try JSONEncoder().encode(data)
            var req = URLRequest(url: URL(string: urlStr)!)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = encodedData
            return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
                URLSession.shared.dataTask(with: req) { data, _, error in
                    guard error == nil, let data = data else {
                        return
                    }
                    do {
                        let msgDict = try JSONSerialization.jsonObject(with: data)
                        os_log("logout response is: %@", log: getTorusLogger(log: Web3AuthLogger.network, type: .info), type: .info, "\(msgDict)")
                        continuation.resume()
                    } catch let err {
                        continuation.resume(throwing: err)
                    }
                }.resume()
            })
        } catch let error {
            throw Web3AuthError.runtimeError(error.localizedDescription)
        }
    }
}
