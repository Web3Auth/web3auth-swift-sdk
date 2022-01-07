import Foundation

/**
 User's info obtained from OpenLogin.
 */
public struct OpenLoginUserInfo: Decodable {
    public let name: String
    public let profileImage: String?
    public let typeOfLogin: String
}
