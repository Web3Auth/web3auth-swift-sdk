import Foundation

/**
 User's credentials obtained from OpenLogin.
 What values are available depends on what type of authentication you perfomed.
 */
@objc(OpenLoginCredentials)
public class Credentials: NSObject, JSONObjectPayload, NSSecureCoding {
    @objc public let privKey: String?
    @objc public let walletKey: String?
    @objc public let tKey: String?
    @objc public let oAuthPrivateKey: String?

    @objc public init(privKey: String? = nil, walletKey: String? = nil, tKey: String? = nil, oAuthPrivateKey: String? = nil) {
        self.privKey = privKey
        self.walletKey = walletKey
        self.tKey = tKey
        self.oAuthPrivateKey = oAuthPrivateKey
    }
    
    // MARK: - JSONObjectPayload

    convenience required public init(json: [String: Any]) {
        self.init(privKey: json["privKey"] as? String, walletKey: json["walletKey"] as? String, tKey: json["tKey"] as? String, oAuthPrivateKey: json["oAuthPrivateKey"] as? String)
    }

    // MARK: - NSSecureCoding

    convenience required public init?(coder aDecoder: NSCoder) {
        let privKey = aDecoder.decodeObject(forKey: "privKey")
        let walletKey = aDecoder.decodeObject(forKey: "walletKey")
        let tKey = aDecoder.decodeObject(forKey: "tKey")
        let oAuthPrivateKey = aDecoder.decodeObject(forKey: "oAuthPrivateKey")
        self.init(privKey: privKey as? String, walletKey: walletKey as? String, tKey: tKey as? String, oAuthPrivateKey: oAuthPrivateKey as? String)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.privKey, forKey: "privKey")
        aCoder.encode(self.walletKey, forKey: "walletKey")
        aCoder.encode(self.tKey, forKey: "tKey")
        aCoder.encode(self.oAuthPrivateKey, forKey: "oAuthPrivateKey")
    }

    public static var supportsSecureCoding: Bool = true
}
