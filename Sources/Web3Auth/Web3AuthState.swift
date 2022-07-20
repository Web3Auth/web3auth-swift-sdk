import Foundation

/**
 User's credentials and info obtained from Web3Auth.
 */
public struct Web3AuthState: Decodable {
    public let privKey: String
    public let ed25519PrivKey: String
    public let sessionId: String
    public let userInfo: Web3AuthUserInfo
}

extension Web3AuthState {
    init?(dict: [String: Any],sessionID:String) {
        guard let privKey = dict["privKey"] as? String,
              let ed25519PrivKey = dict["ed25519PrivKey"] as? String,
              let userInfoDict = dict["store"] as? [String: String],
              let userInfo = Web3AuthUserInfo(dict: userInfoDict)
        else { return nil }
        self.privKey = privKey
        self.ed25519PrivKey = ed25519PrivKey
        self.sessionId = sessionID
        self.userInfo = userInfo
    }
}
