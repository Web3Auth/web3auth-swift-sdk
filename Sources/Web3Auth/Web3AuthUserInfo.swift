import Foundation

/**
 User's info obtained from Web3Auth.
 */
public struct Web3AuthUserInfo: Decodable {
    public let name: String
    public let typeOfLogin: String
    public let profileImage: String?
    public let aggregateVerifier: String?
    public let verifier: String?
    public let verifierId: String?
    public let email: String?
    public let dappShare: String?
    public let idToken: String?
    public let oAuthIdToken: String?
}

extension Web3AuthUserInfo {
    init?(dict: [String: String]) {
        guard let name = dict["name"],
              let typeOfLogin = dict["typeOfLogin"] else { return nil }
        self.name = name
        self.typeOfLogin = typeOfLogin
        profileImage = dict["profileImage"] ?? ""
        aggregateVerifier = dict["aggregateVerifier"] ?? ""
        verifier = dict["verifier"] ?? ""
        verifierId = dict["verifierId"] ?? ""
        email = dict["email"] ?? ""
        dappShare = dict["dappShare"] ?? ""
        idToken = dict["idToken"] ?? ""
        oAuthIdToken = dict["oAuthIdToken"] ?? ""
    }
}
