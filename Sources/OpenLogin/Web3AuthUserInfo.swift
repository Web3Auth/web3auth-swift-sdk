import Foundation

/**
 User's info obtained from OpenLogin.
 */
public struct Web3AuthUserInfo: Decodable {
    public let name: String
    public let profileImage: String?
    public let typeOfLogin: String
    public let aggregateVerifier: String?
    public let verifier: String?
    public let verifierId: String?
    public let email: String?
}
