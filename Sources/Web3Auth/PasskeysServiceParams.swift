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
    case PLATFORM
    case CROSS_PLATFORM
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
    public let data: Data
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        data = try container.decode(Data.self, forKey: .data)
    }
}

// Data object containing the registration options and tracking ID
public struct Data: Decodable {
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

public struct AuthParamsData {
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

public struct MetadataInfo {
    public let privKey: String
//    public let userInfo: UserInfo
}

public struct VerifyRequest {
    public let web3auth_client_id: String
    public let tracking_id: String
//    public let verification_data: CreatePublicKeyCredentialResponse
    public let network: String
    public let signatures: [String]
    public let metadata: String
}

public struct VerifyRegistrationResponse {
    public let verified: Bool
    public let error: String?
    public let data: ChallengeData?
}

public struct ChallengeData {
    public let challenge_timestamp: String
    public let credential_public_key: String
}

public struct RegistrationResponseJson {
    public let rawId: String
    public let authenticatorAttachment: String
    public let type: String
    public let id: String
    public let response: Response
    public let clientExtensionResults: ClientExtensionResults
}

public struct Response {
    public let clientDataJSON: String
    public let attestationObject: String
    public let transports: [String]
    public let authenticatorData: String
    public let publicKeyAlgorithm: UInt
    public let publicKey: String
}

public struct ClientExtensionResults {
    public let credProps: CredProps
}

public struct CredProps {
    public let rk: Bool
}
