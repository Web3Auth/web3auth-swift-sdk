//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 18/07/22.
//

import SessionManager


extension KeychainManager {
    
    func saveDappShare(userInfo: Web3AuthUserInfo) {
        guard let verifer = userInfo.verifier, let veriferID = userInfo.verifierId, let dappShare = userInfo.dappShare else { return }
        let key = verifer + " | " + veriferID
        KeychainManager.shared.save(key: .custom(dappShare), val: key)
    }

    func getDappShare(verifier: String) -> String? {
        return searchDappShare(query: verifier)
    }

    private func searchDappShare(query: String) -> String? {
        let allKeys = KeychainManager.shared.getAllKeys
        var result: String?
        allKeys.forEach { key in
            if key.contains(query) {
                result = KeychainManager.shared.get(key: .custom(key))
                return
            }
        }
        return result
    }
}
