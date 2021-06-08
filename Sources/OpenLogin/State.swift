import Foundation

/**
 User's credentials and info obtained from OpenLogin.
 */
public struct State: Decodable {
    public let privKey: String
    public let userInfo: UserInfo
}
