import Foundation

/**
 User's credentials and info obtained from OpenLogin.
 */
public struct OpenLoginState: Decodable {
    public let privKey: String
    public let userInfo: OpenLoginUserInfo
}
