import Foundation

/**
 User's info obtained from Web3Auth.
 */
public struct Web3AuthUserInfo: Decodable {
    public let name: String
    public let profileImage: String?
    public let typeOfLogin: String
    public let aggregateVerifier: String?
    public let verifier: String?
    public let verifierId: String?
    public let email: String?
    public let dappShare: String?
    public let idToken: String?
    public let oAuthIdToken: String?
}
