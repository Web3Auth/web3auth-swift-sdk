//
//  File.swift
//  
//
//  Created by Ayush B on 13/08/24.
//

import Foundation

public struct PasskeysServiceParams: Codable {
    public let web3AuthClientId: String
    public let web3AuthNetwork: Network
    public let buildEnv: BuildEnv
    public let rpId: String
    public let rpName: String
}

public struct RegistrationOptionsParams: Codable {
    public let oAuthVerifier: String
    public let oAuthVerifierId: String
    public let signatures: [String]
    public let username: String
    public let passkeyToken: String?
    public let authenticatorAttachment: AuthenticatorAttachment
}

public enum AuthenticatorAttachment: String, Codable {
    case platform
    case cross_platform
}

public struct RegistrationOptionsData {
    public let options: [String: Any]
    public let trackingId: String
}

public struct RegistrationOptionsRequest : Codable{
    public let web3auth_client_id: String
    public let verifier_id: String
    public let verifier: String
    public let rp: Rp
    public let username: String
    public let network: String
    public let signatures: [String]
}

public struct Rp : Codable {
    public let name: String
    public let id: String
    
    public init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}

public struct RegistrationOptionsResponse {
    public let success: Bool
    public let data: RegistrationOptionsData
}

public struct PasskeyServiceEndpoints: Codable{
    public let register: RegisterEndpoints
    public let authenticate: AuthenticateEndpoints
    public let crud: CrudEndpoints
}

public struct RegisterEndpoints : Codable{
    public let options: String
    public let verify: String
}

public struct AuthenticateEndpoints: Codable {
    public let options: String
    public let verify: String
}

public struct CrudEndpoints: Codable {
    public let list: String
}

public struct RegistrationResponse: Decodable {
    public let success: Bool
    public let data: RegisterData
    
    enum CodingKeys: String, CodingKey {
        case success
        case data = "data"
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        data = try container.decode(RegisterData.self, forKey: .data)
    }
}

// Data object containing the registration options and tracking ID
public struct RegisterData: Decodable {
    public let options: Options
    public let trackingId: String
    
    enum CodingKeys: String, CodingKey {
        case options
        case trackingId
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        options = try container.decode(Options.self, forKey: .options)
        trackingId = try container.decode(String.self, forKey: .trackingId)
    }
}

// Options object containing various registration parameters
public struct Options: Decodable {
    public let challenge: String
    public let rp: Rp
    public let user: User
    public let pubKeyCredParams: [PubKeyCredParam]
    public let timeout: UInt
    public let attestation: String
    public let excludeCredentials: [String]
    public let authenticatorSelection: AuthenticatorSelection
    public let extensions: Extensions
    
    enum CodingKeys: String, CodingKey {
        case challenge
        case rp
        case user
        case pubKeyCredParams
        case timeout
        case attestation
        case excludeCredentials
        case authenticatorSelection
        case extensions
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challenge = try container.decode(String.self, forKey: .challenge)
        rp = try container.decode(Rp.self, forKey: .rp)
        user = try container.decode(User.self, forKey: .user)
        pubKeyCredParams = try container.decode([PubKeyCredParam].self, forKey: .pubKeyCredParams)
        timeout = try container.decode(UInt.self, forKey: .timeout)
        attestation = try container.decode(String.self, forKey: .attestation)
        excludeCredentials = try container.decode([String].self, forKey: .excludeCredentials)
        authenticatorSelection = try container.decode(AuthenticatorSelection.self, forKey: .authenticatorSelection)
        extensions = try container.decode(Extensions.self, forKey: .extensions)
    }
}

// User object containing user information
public struct User: Decodable {
    public let id: String
    public let name: String
    public let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
    }
    
}

// PubKeyCredParam object representing public key credential parameters
public struct PubKeyCredParam: Decodable {
    public let alg: Int
    public let type: String
    
    enum CodingKeys: String, CodingKey {
        case alg
        case type
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alg = try container.decode(Int.self, forKey: .alg)
        type = try container.decode(String.self, forKey: .type)
    }
}

public struct  AuthenticatorSelection: Decodable {
    public let userVerification: String
    public let residentKey: String
    public let requireResidentKey: Bool
    
    enum CodingKeys: String, CodingKey {
        case userVerification
        case residentKey
        case requireResidentKey
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userVerification = try container.decode(String.self, forKey: .userVerification)
        residentKey = try container.decode(String.self, forKey: .residentKey)
        requireResidentKey = try container.decode(Bool.self, forKey: .requireResidentKey)
    }
}

// Extensions object containing any additional extensions
public struct Extensions: Decodable{
    public let credProps: Bool
    
    enum CodingKeys: String, CodingKey {
        case credProps
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        credProps = try container.decode(Bool.self, forKey: .credProps)
    }
    
}

/*public struct AuthParamsData {
    public let rpIdHash: [UInt8]
    public let flagsBuf: [UInt8]
    public let flags: Flags
    public let counter: UInt
    public let counterBuf: [UInt8]
    public let aaguid: [UInt8]
    public let credID: [UInt8]
    public let COSEPublicKey: [UInt8]
}

public struct Flags {
    public let up: Bool
    public let uv: Bool
    public let at: Bool
    public let ed: Bool
    public let flagsInt: Int
}

public struct MetadataInfo: Encodable {
    public let privKey: String
    public let userInfo: Web3AuthUserInfo
}*/

public struct AuthParamsData {
    let rpIdHash: Data
    let flagsBuf: Data
    let flags: Flags
    let counter: UInt32
    let counterBuf: Data
    let aaguid: Data
    let credID: Data
    let COSEPublicKey: Data
    
    public struct Flags {
        let up: Bool
        let uv: Bool
        let at: Bool
        let ed: Bool
        let flagsInt: UInt8
    }
}

public struct VerifyRequest: Encodable {
    public let web3auth_client_id: String
    public let tracking_id: String
    public let verification_data: Data
    public let network: String
    public let signatures: [String]
    public let metadata: String

    enum CodingKeys: String, CodingKey {
        case web3auth_client_id
        case tracking_id
        case verification_data
        case network
        case signatures
        case metadata
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(web3auth_client_id, forKey: .web3auth_client_id)
        try container.encode(tracking_id, forKey: .tracking_id)
        try container.encode(verification_data, forKey: .verification_data)
        try container.encode(network, forKey: .network)
        try container.encode(signatures, forKey: .signatures)
        try container.encode(metadata, forKey: .metadata)
    }
}

public struct VerifyRegistrationResponse: Decodable {
    public let verified: Bool
    public let error: String?
    public let data: ChallengeData?
    
    enum CodingKeys: String, CodingKey {
        case verified
        case error
        case data
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        verified = try container.decode(Bool.self, forKey: .verified)
        error = try container.decode(String.self, forKey: .error)
        data = try container.decode(ChallengeData.self, forKey: .data)
    }
}

public struct ChallengeData: Decodable {
    public let challenge_timestamp: String
    public let credential_public_key: String
    
    enum CodingKeys: String, CodingKey {
        case challenge_timestamp
        case credential_public_key
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challenge_timestamp = try container.decode(String.self, forKey: .challenge_timestamp)
        credential_public_key = try container.decode(String.self, forKey: .credential_public_key)
    }
}

public struct RegistrationResponseJson: Decodable {
    public let rawId: String
    public let authenticatorAttachment: String
    public let type: String
    public let id: String
    public let response: Response
    public let clientExtensionResults: ClientExtensionResults
    
    enum CodingKeys: String, CodingKey {
        case rawId
        case authenticatorAttachment
        case type
        case id
        case response
        case clientExtensionResults
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rawId = try container.decode(String.self, forKey: .rawId)
        authenticatorAttachment = try container.decode(String.self, forKey: .authenticatorAttachment)
        type = try container.decode(String.self, forKey: .type)
        id = try container.decode(String.self, forKey: .id)
        response = try container.decode(Response.self, forKey: .response)
        clientExtensionResults = try container.decode(ClientExtensionResults.self, forKey: .clientExtensionResults)
    }
    
}

public struct Response: Decodable {
    public let clientDataJSON: String
    public let attestationObject: String
    public let transports: [String]
    public let authenticatorData: String
    public let publicKeyAlgorithm: UInt
    public let publicKey: String
    
    enum CodingKeys: String, CodingKey {
        case clientDataJSON
        case attestationObject
        case transports
        case authenticatorData
        case publicKeyAlgorithm
        case publicKey
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        clientDataJSON = try container.decode(String.self, forKey: .clientDataJSON)
        attestationObject = try container.decode(String.self, forKey: .attestationObject)
        transports = try container.decode([String].self, forKey: .transports)
        authenticatorData = try container.decode(String.self, forKey: .authenticatorData)
        publicKeyAlgorithm = try container.decode(UInt.self, forKey: .publicKeyAlgorithm)
        publicKey = try container.decode(String.self, forKey: .publicKey)
    }
    
}

public struct ClientExtensionResults: Decodable {
    public let credProps: CredProps
    
    enum CodingKeys: String, CodingKey {
        case credProps
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        credProps = try container.decode(CredProps.self, forKey: .credProps)
    }
    
}

public struct CredProps: Decodable {
    public let rk: Bool
    
    enum CodingKeys: String, CodingKey {
        case rk
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rk = try container.decode(Bool.self, forKey: .rk)
    }
}

public struct AuthenticationOptionsRequest: Codable {
    let web3authClientId: String
    let rpId: String
    let authenticatorId: String?
    let network: String
    
    enum CodingKeys: String, CodingKey {
        case web3authClientId = "web3auth_client_id"
        case rpId = "rp_id"
        case authenticatorId = "authenticator_id"
        case network
    }
}

public struct AuthenticationOptionsResponse: Decodable {
    let success: Bool
    let data: AuthenticationOptionsData
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        data = try container.decode(AuthenticationOptionsData.self, forKey: .data)
    }
}

public struct AuthenticationOptionsData: Decodable {
    let options: AuthOptions
    let trackingId: String
    
    enum CodingKeys: String, CodingKey {
        case options
        case trackingId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        options = try container.decode(AuthOptions.self, forKey: .options)
        trackingId = try container.decode(String.self, forKey: .trackingId)
    }
}

public struct AuthOptions: Decodable {
    let challenge: String
    let allowCredentials: [Data?]
    let timeout: UInt64
    let userVerification: String
    let rpId: String
    
    enum CodingKeys: String, CodingKey {
        case challenge
        case allowCredentials
        case timeout
        case userVerification
        case rpId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challenge = try container.decode(String.self, forKey: .challenge)
        allowCredentials = try container.decode([Data].self, forKey: .timeout)
        timeout = try container.decode(UInt64.self, forKey: .timeout)
        userVerification = try container.decode(String.self, forKey: .userVerification)
        rpId = try container.decode(String.self, forKey: .rpId)
    }
}

public struct VerifyAuthenticationRequest : Codable {
    let web3authClientId: String
    let trackingId: String
    let verificationData: Data
    let network: String
}

public struct VerifyAuthenticationResponse: Codable {
    let verified: Bool
    let data: AuthData?
    let error: String?
}

public struct AuthData: Codable {
    let challenge: String
    let transports: [String]
    let publicKey: String
    let idToken: String
    let metadata: String
    let verifierId: String
    
    enum CodingKeys: String, CodingKey {
        case challenge
        case transports
        case publicKey
        case idToken
        case metadata
        case verifierId
    }
}

public struct ExtraVerifierParams: Codable {
    let signature: String?
    let clientDataJSON: String
    let authenticatorData: String
    let publicKey: String
    let challenge: String
    let rpOrigin: String
    let rpId: String
    let credId: String
    
    enum CodingKeys: String, CodingKey {
        case signature
        case clientDataJSON = "clientDataJSON"
        case authenticatorData = "authenticatorData"
        case publicKey
        case challenge
        case rpOrigin = "rpOrigin"
        case rpId = "rpId"
        case credId = "credId"
    }
}

public struct PassKeyLoginParams: Codable {
    let verifier: String
    let verifierId: String
    let idToken: String
    let extraVerifierParams: ExtraVerifierParams
    
    enum CodingKeys: String, CodingKey {
        case verifier
        case verifierId = "verifierId"
        case idToken
        case extraVerifierParams = "extraVerifierParams"
    }
}

