//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 18/07/22.
//

import Foundation
import KeychainSwift

class KeychainManager {
    private let keychain = KeychainSwift()
    static let shared = KeychainManager()

    private init() {}

    func saveDappShare(userInfo: Web3AuthUserInfo) {
        guard let verifer = userInfo.verifier, let veriferID = userInfo.verifierId, let dappShare = userInfo.dappShare else { return }
        keychain.set(dappShare, forKey: verifer + veriferID)
    }

    func getDappShare(verifier: String) -> String? {
        return searchDappShare(query: verifier)
    }
    
    func removeDappShare(key:String){
        keychain.delete(key)
    }

    private func searchDappShare(query: String) -> String? {
        let allKeys = keychain.allKeys
        var result: String?
        allKeys.forEach { key in
            if key.contains(query) {
                result = keychain.get(key)
                return
            }
        }
        return result
    }
}
