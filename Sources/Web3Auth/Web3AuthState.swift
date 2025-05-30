import Foundation
import FetchNodeDetails

/**
 User's credentials and info obtained from Web3Auth.
 */
public struct Web3AuthResponse: Codable {
    public let privateKey: String?
    public let ed25519PrivateKey: String?
    public let sessionId: String?
    public let userInfo: Web3AuthUserInfo?
    public let error: String?
    public let coreKitKey: String?
    public let coreKitEd25519PrivKey: String?
    public var factorKey: String?
    public var signatures: [String]?
    public var tssShareIndex: Int?
    public var tssPubKey: String?
    public var tssShare: String?
    public var tssTag: String?
    public var tssNonce: Int?
    public var nodeIndexes: [Int]?
    public var keyMode: String?
    
    enum CodingKeys: String, CodingKey {
        case privateKey = "privKey"
        case ed25519PrivateKey = "ed25519PrivKey"
        case sessionId
        case userInfo
        case error
        case coreKitKey
        case coreKitEd25519PrivKey
        case factorKey
        case signatures
        case tssShareIndex
        case tssPubKey
        case tssShare
        case tssTag
        case tssNonce
        case nodeIndexes
        case keyMode
    }

    public init(privateKey: String?, ed25519PrivateKey: String?, sessionId: String?, userInfo: Web3AuthUserInfo?, error: String?,
                coreKitKey: String?, coreKitEd25519PrivKey: String?, factorKey: String?, signatures: [String]?, tssShareIndex: Int?, tssPubKey: String?, tssShare: String?, tssTag: String? ,tssNonce: Int?, nodeIndexes: [Int]?, keyMode: String?) {
        self.privateKey = privateKey
        self.ed25519PrivateKey = ed25519PrivateKey
        self.sessionId = sessionId
        self.userInfo = userInfo
        self.error = error
        self.coreKitKey = coreKitKey
        self.coreKitEd25519PrivKey = coreKitEd25519PrivKey
        self.factorKey = factorKey
        self.signatures = signatures
        self.tssShareIndex = tssShareIndex
        self.tssPubKey = tssPubKey
        self.tssShare = tssShare
        self.tssTag = tssTag
        self.tssNonce = tssNonce
        self.nodeIndexes = nodeIndexes
        self.keyMode = keyMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        privateKey = try container.decodeIfPresent(String.self, forKey: .privateKey)
        ed25519PrivateKey = try container.decodeIfPresent(String.self, forKey: .ed25519PrivateKey)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        userInfo = try container.decodeIfPresent(Web3AuthUserInfo.self, forKey: .userInfo)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        coreKitKey = try container.decodeIfPresent(String.self, forKey: .coreKitKey)
        coreKitEd25519PrivKey = try container.decodeIfPresent(String.self, forKey: .coreKitEd25519PrivKey)
        factorKey = try container.decodeIfPresent(String.self, forKey: .factorKey)
        signatures = try container.decodeIfPresent([String].self, forKey: .signatures)
        tssShareIndex = try container.decodeIfPresent(Int.self, forKey: .tssShareIndex)
        tssPubKey = try container.decodeIfPresent(String.self, forKey: .tssPubKey)
        tssShare = try container.decodeIfPresent(String.self, forKey: .tssShare)
        tssTag = try container.decodeIfPresent(String.self, forKey: .tssTag)
        tssNonce = try container.decodeIfPresent(Int.self, forKey: .tssNonce)
        nodeIndexes = try container.decodeIfPresent([Int].self, forKey: .nodeIndexes)
        keyMode = try container.decodeIfPresent(String.self, forKey: .keyMode)
    }
}

extension Web3AuthResponse {
    init?(dict: [String: Any], sessionID: String, web3AuthNetwork: Web3AuthNetwork) {
        guard let privateKey = dict["privKey"] as? String,
              let ed25519PrivateKey = dict["ed25519PrivKey"] as? String,
              let userInfoDict = dict["userInfo"] as? [String: Any],
              let userInfo = Web3AuthUserInfo(dict: userInfoDict)
        else { return nil }
        let error = dict["error"] as? String
        self.privateKey = privateKey
        self.ed25519PrivateKey = ed25519PrivateKey
        sessionId = sessionID
        self.userInfo = userInfo
        self.error = error
        coreKitKey = dict["coreKitKey"] as? String ?? ""
        coreKitEd25519PrivKey = dict["coreKitEd25519PrivKey"] as? String ?? ""
        factorKey = dict["factorKey"] as? String
        signatures = dict["signatures"] as? [String]
        tssShareIndex = dict["tssShareIndex"] as? Int
        tssPubKey = dict["tssPubKey"] as? String
        tssShare = dict["tssShare"] as? String
        tssTag = dict["tssTag"] as? String
        tssNonce = dict["tssShare"] as? Int
        nodeIndexes = dict["nodeIndexes"] as? [Int]
        keyMode = dict["keyMode"] as? String
    }
}
