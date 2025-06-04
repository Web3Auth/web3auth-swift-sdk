import Foundation
import JWTKit

// JWT payload structure.
struct TestPayload: JWTPayload, Equatable {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case isAdmin = "admin"
        case emailVerified = "email_verified"
        case issuer = "iss"
        case iat
        case email
        case audience = "aud"
        case name
    }

    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var audience: AudienceClaim
    var isAdmin: Bool
    let emailVerified: Bool
    var issuer: IssuerClaim
    var iat: IssuedAtClaim
    var email: String
    var name: String

    // call its verify method.
    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}


func generateRandomEmail(of length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    var s = ""
    for _ in 0 ..< length {
        s.append(letters.randomElement()!)
    }
    return s + "@gmail.com"
}

func generateIdToken(email: String) throws -> String {
    let verifierPrivateKeyForSigning =
        """
        -----BEGIN PRIVATE KEY-----
        MEECAQAwEwYHKoZIzj0CAQYIKoZIzj0DAQcEJzAlAgEBBCCD7oLrcKae+jVZPGx52Cb/lKhdKxpXjl9eGNa1MlY57A==
        -----END PRIVATE KEY-----
        """

    do {
        let signers = JWTSigners()
        let keys = try ECDSAKey.private(pem: verifierPrivateKeyForSigning)
        signers.use(.es256(key: keys))

        // Parses the JWT and verifies its signature.
        let today = Date()
        let modifiedDate = Calendar.current.date(byAdding: .minute, value: 2, to: today)!

        let emailComponent = email.components(separatedBy: "@")[0]
        let subject = "email|" + emailComponent

        let payload = TestPayload(
            subject: SubjectClaim(stringLiteral: subject),
            expiration: ExpirationClaim(value: modifiedDate), // eat
            audience: "torus-key-test",
            isAdmin: false,
            emailVerified: true,
            issuer: "torus-key-test",
            iat: IssuedAtClaim(value: today),
            email: email,
            name: email)
        let jwt = try signers.sign(payload)
        return jwt
    } catch {
        throw error
    }
}
