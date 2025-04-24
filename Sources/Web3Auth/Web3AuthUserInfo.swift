import Foundation

/**
 User's info obtained from Web3Auth.
 */
public struct Web3AuthUserInfo: Codable {
    public let name: String?
    public let profileImage: String?
    public let groupedAuthConnectionId: String?
    public let authConnectionId: String?
    public let userId: String?
    public let email: String?
    public let dappShare: String?
    public let idToken: String?
    public let oAuthIdToken: String?
    public let oAuthAccessToken: String?
    public let isMfaEnabled: Bool?
    public let authConnection: String?
    public let appState: String?

    public init(name: String?, profileImage: String?, groupedAuthConnectionId: String?,
                authConnectionId: String?, userId: String?, email: String?, dappShare: String?, idToken: String?, oAuthIdToken: String?, oAuthAccessToken: String?,
                isMfaEnabled: Bool?, authConnection: String?, appState: String?) {
        self.name = name
        self.profileImage = profileImage
        self.groupedAuthConnectionId = groupedAuthConnectionId
        self.authConnectionId = authConnectionId
        self.userId = userId
        self.email = email
        self.dappShare = dappShare
        self.idToken = idToken
        self.oAuthIdToken = oAuthIdToken
        self.oAuthAccessToken = oAuthAccessToken
        self.isMfaEnabled = isMfaEnabled
        self.authConnection = authConnection
        self.appState = appState
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
        groupedAuthConnectionId = try container.decodeIfPresent(String.self, forKey:.groupedAuthConnectionId)
        authConnectionId = try container.decodeIfPresent(String.self, forKey: .authConnectionId)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        dappShare = try container.decodeIfPresent(String.self, forKey: .dappShare)
        idToken = try container.decodeIfPresent(String.self, forKey: .idToken)
        oAuthIdToken = try container.decodeIfPresent(String.self, forKey: .oAuthIdToken)
        oAuthAccessToken = try container.decodeIfPresent(String.self, forKey: .oAuthAccessToken)
        isMfaEnabled = try container.decodeIfPresent(Bool.self, forKey: .isMfaEnabled)
        authConnection = try container.decodeIfPresent(String.self, forKey: .authConnection)
        appState = try container.decodeIfPresent(String.self, forKey: .appState)
    }
}

extension Web3AuthUserInfo {
    init?(dict: [String: Any]) {
        name = dict["name"] as? String ?? ""
        profileImage = dict["profileImage"] as? String ?? ""
        groupedAuthConnectionId = dict["groupedAuthConnectionId"] as? String ?? ""
        authConnectionId = dict["authConnectionId"] as? String ?? ""
        userId = dict["userId"] as? String ?? ""
        email = dict["email"] as? String ?? ""
        dappShare = dict["dappShare"] as? String ?? ""
        idToken = dict["idToken"] as? String ?? ""
        oAuthIdToken = dict["oAuthIdToken"] as? String ?? ""
        oAuthAccessToken = dict["oAuthAccessToken"] as? String ?? ""
        isMfaEnabled = dict["isMfaEnabled"] as? Bool ?? false
        authConnection = dict["authConnection"] as? String ?? ""
        appState = dict["appState"] as? String ?? ""
    }
}
