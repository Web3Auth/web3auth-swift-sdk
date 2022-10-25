import Foundation

/**
 User's info obtained from Web3Auth.
 */
public struct Web3AuthUserInfo: Codable {
    public let name: String?
    public let profileImage: String?
    public let typeOfLogin: String?
    public let aggregateVerifier: String?
    public let verifier: String?
    public let verifierId: String?
    public let email: String?
    public let dappShare: String?
    public let idToken: String?
    public let oAuthIdToken: String?
    public let oAuthAccessToken: String?

    public init(name: String?, profileImage: String?, typeOfLogin: String?, aggregateVerifier: String?,
                verifier: String?, verifierId: String?, email: String?, dappShare: String?, idToken: String?, oAuthIdToken: String?, oAuthAccessToken: String?) {
        self.name = name
        self.profileImage = profileImage
        self.typeOfLogin = typeOfLogin
        self.aggregateVerifier = aggregateVerifier
        self.verifier = verifier
        self.verifierId = verifierId
        self.email = email
        self.dappShare = dappShare
        self.idToken = idToken
        self.oAuthIdToken = oAuthIdToken
        self.oAuthAccessToken = oAuthAccessToken
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
        typeOfLogin = try container.decodeIfPresent(String.self, forKey: .typeOfLogin)
        aggregateVerifier = try container.decodeIfPresent(String.self, forKey: .aggregateVerifier)
        verifier = try container.decodeIfPresent(String.self, forKey: .verifier)
        verifierId = try container.decodeIfPresent(String.self, forKey: .verifierId)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        dappShare = try container.decodeIfPresent(String.self, forKey: .dappShare)
        idToken = try container.decodeIfPresent(String.self, forKey: .idToken)
        oAuthIdToken = try container.decodeIfPresent(String.self, forKey: .oAuthIdToken)
        oAuthAccessToken = try container.decodeIfPresent(String.self, forKey: .oAuthAccessToken)
    }
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
        oAuthAccessToken = dict["oAuthAccessToken"] ?? ""
    }
}
