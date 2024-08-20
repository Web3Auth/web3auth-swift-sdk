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

public struct RegistrationResponse {
    public let success: Bool
    public let data: Data
}

// Data object containing the registration options and tracking ID
public struct Data {
    public let options: Options
    public let trackingId: String
}

// Options object containing various registration parameters
public struct Options {
    public let challenge: String
    public let rp: Rp
    public let user: User
    public let pubKeyCredParams: [PubKeyCredParam]
    public let timeout: UInt
    public let attestation: String
    public let excludeCredentials: [String]
    public let authenticatorSelection: AuthenticatorSelection
    public let extensions: Extensions
}

// User object containing user information
public struct User {
    public let id: String
    public let name: String
    public let displayName: String
}

// PubKeyCredParam object representing public key credential parameters
public struct PubKeyCredParam {
    public let alg: Int
    public let type: String
}

public struct  AuthenticatorSelection {
    public let userVerification: String
    public let residentKey: String
    public let requireResidentKey: Bool
}

// Extensions object containing any additional extensions
public struct Extensions{
    public let credProps: Bool
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
