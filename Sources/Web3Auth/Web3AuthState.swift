import Foundation

/**
 User's credentials and info obtained from Web3Auth.
 */
public struct Web3AuthState: Codable {
    public let privKey: String?
    public let ed25519PrivKey: String?
    public let sessionId: String?
    public let userInfo: Web3AuthUserInfo?
    public let error: String?

    public init(privKey: String?, ed25519PrivKey: String?, sessionId: String?, userInfo: Web3AuthUserInfo?, error: String?) {
        self.privKey = privKey
        self.ed25519PrivKey = ed25519PrivKey
        self.sessionId = sessionId
        self.userInfo = userInfo
        self.error = error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        privKey = try container.decodeIfPresent(String.self, forKey: .privKey)
        ed25519PrivKey = try container.decodeIfPresent(String.self, forKey: .ed25519PrivKey)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        userInfo = try container.decodeIfPresent(Web3AuthUserInfo.self, forKey: .userInfo)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }
}


extension Web3AuthState {
    init?(dict: [String: Any],sessionID:String) {
        guard let privKey = dict["privKey"] as? String,
              let ed25519PrivKey = dict["ed25519PrivKey"] as? String,
              let userInfoDict = dict["store"] as? [String: String],
              let userInfo = Web3AuthUserInfo(dict: userInfoDict)
        else { return nil }
        let error = dict["error"] as? String
        self.privKey = privKey
        self.ed25519PrivKey = ed25519PrivKey
        self.sessionId = sessionID
        self.userInfo = userInfo
        self.error = error
    }
}
