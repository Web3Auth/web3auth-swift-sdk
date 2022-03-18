import Foundation

/**
 User's credentials and info obtained from Web3Auth.
 */
public struct Web3AuthState: Decodable {
    public let privKey: String
    public let ed25519PrivKey: String
    public let userInfo: Web3AuthUserInfo
}
