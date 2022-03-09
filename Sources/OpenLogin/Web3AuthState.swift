import Foundation

/**
 User's credentials and info obtained from OpenLogin.
 */
public struct Web3AuthState: Decodable {
    public let privKey: String
    public let userInfo: Web3AuthUserInfo
}
