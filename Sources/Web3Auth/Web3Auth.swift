import AuthenticationServices
import OSLog
import SessionManager
import FetchNodeDetails
import TorusUtils
import Foundation
import SwiftCbor
import struct TorusUtils.ECIES
#if canImport(curveSecp256k1)
    import curveSecp256k1
#endif

/**
 Authentication using Web3Auth.
 */

public class Web3Auth: NSObject {
    
    private var initParams: W3AInitParams
    private var authSession: ASWebAuthenticationSession?
    // You can check the state variable before logging the user in, if the user
    // has an active session the state variable will already have all the values you
    // get from login so the user does not have to re-login
    public var state: Web3AuthState?
    var sessionManager: SessionManager
    var webViewController: WebViewController = DispatchQueue.main.sync { WebViewController(onSignResponse: { _ in }) }
    private var w3ALoginParams: W3ALoginParams?
    private static var signResponse: SignResponse?
    private var trackingId: String?
    private var rpId: String?

    let SIGNER_MAP: [Network: String] = [
        .mainnet: "https://signer.web3auth.io",
        .testnet: "https://signer.web3auth.io",
        .cyan: "https://signer-polygon.web3auth.io",
        .aqua: "https://signer-polygon.web3auth.io",
        .sapphire_mainnet: "https://signer.web3auth.io",
        .sapphire_devnet: "https://signer.web3auth.io",
    ]
    
    let PASSKEY_SVC_URL: [BuildEnv: String] = [
        .testing: "https://api-develop-passwordless.web3auth.io",
        .staging: "https://api-passwordless.web3auth.io",
        .production: "https://api-passwordless.web3auth.io"
    ]
    
    let WEB3AUTH_NETWORK_MAP: [Network: Web3AuthNetwork] = [
        .mainnet: Web3AuthNetwork.MAINNET,
        .testnet: Web3AuthNetwork.TESTNET,
        .aqua: Web3AuthNetwork.AQUA,
        .cyan: Web3AuthNetwork.CYAN,
        .sapphire_devnet: Web3AuthNetwork.SAPPHIRE_DEVNET,
        .sapphire_mainnet: Web3AuthNetwork.SAPPHIRE_MAINNET
    ]
    /**
     Web3Auth  component for authenticating with web-based flow.

     ```
     Web3Auth(OLInitParams(clientId: clientId, network: .mainnet))
     ```

     - parameter params: Init params for your Web3Auth instance.

     - returns: Web3Auth component.
     */
    public init(_ params: W3AInitParams) async throws {
        initParams = params
        Router.baseURL = SIGNER_MAP[params.network] ?? ""
        sessionManager = SessionManager(sessionTime: params.sessionTime, allowedOrigin: params.redirectUrl)
        super.init()
        do {
            let fetchConfigResult = try await fetchProjectConfig()
            if fetchConfigResult {
                let sessionId = SessionManager.getSessionIdFromStorage()
                if sessionId != nil {
                    sessionManager.setSessionId(sessionId: sessionId!)
                    let loginDetailsDict = try await sessionManager.authorizeSession(origin: params.redirectUrl)
                    guard let loginDetails = Web3AuthState(dict: loginDetailsDict, sessionID: sessionManager.getSessionId(),
                                                           network: initParams.network) else { throw Web3AuthError.decodingError }
                    state = loginDetails
                }
            }
        } catch let error {
            os_log("%s", log: getTorusLogger(log: Web3AuthLogger.core, type: .error), type: .error, error.localizedDescription)
            throw error
        }
    }

    public func logout() async throws {
        guard let state = state else { throw Web3AuthError.noUserFound }
        try await sessionManager.invalidateSession()
        SessionManager.deleteSessionIdFromStorage()
        if let verifer = state.userInfo?.verifier, let dappShare = KeychainManager.shared.getDappShare(verifier: verifer) {
            KeychainManager.shared.delete(key: .custom(dappShare))
        }
        self.state = nil
    }

    public func getLoginId<T: Encodable>(data: T) async throws -> String? {
        let sessionId = try SessionManager.generateRandomSessionID()!
        sessionManager.setSessionId(sessionId: sessionId)
        return try await sessionManager.createSession(data: data)
    }

    private func getLoginDetails(_ callbackURL: URL) async throws -> Web3AuthState {
        let loginDetailsDict = try await sessionManager.authorizeSession(origin: initParams.redirectUrl)
        guard
            let loginDetails = Web3AuthState(dict: loginDetailsDict, sessionID: sessionManager.getSessionId(), network: initParams.network)
        else {
            throw Web3AuthError.decodingError
        }
        return loginDetails
    }

    /**
     Web3Auth component for authenticating with web-based flow.

     ```
     Web3Auth()
     ```

     Parameters are loaded from the file `Web3Auth.plist` in your bundle with the following content:

     ```
     <?xml version="1.0" encoding="UTF-8"?>
     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
     <plist version="1.0">
         <dict>
             <key>ClientId</key>
             <string>{YOUR_CLIENT_ID}</string>
             <key>Network</key>
             <string>mainnet|testnet</string>
         </dict>
     </plist>
     ```

     - parameter bundle: Bundle to locate the `Web3Auth.plist` file. By default is the main bundle.

     - returns: Web3Auth component.
     - important: Calling this method without a valid `Web3Auth.plist` will crash your application.
     */
    public convenience init(_ bundle: Bundle = Bundle.main) async throws {
        let values = plistValues(bundle)!
        try await self.init(W3AInitParams(
            clientId: values.clientId,
            network: values.network,
            redirectUrl: values.redirectUrl
        ))
    }

    /**
     Starts the WebAuth flow by modally presenting a ViewController in the top-most controller.

     ```
     Web3Auth()
         .login(provider: .GOOGLE) {
             switch $0 {
             case .success(let result):
                 print("""
                     Signed in successfully!
                         Private key: \(result.privKey)
                         User info:
                             Name: \(result.userInfo.name)
                             Profile image: \(result.userInfo.profileImage ?? "N/A")
                             Type of login: \(result.userInfo.typeOfLogin)
                     """)
             case .failure(let error):
                 print("Error: \(error)")
             }
         }
     ```

     Any on going WebAuth auth session will be automatically cancelled when starting a new one,
     and it's corresponding callback with be called with a failure result of `Web3AuthError.appCancelled`

     - parameter callback: Callback called with the result of the WebAuth flow.
     */
    @MainActor public func login(_ loginParams: W3ALoginParams) async throws -> Web3AuthState {
        guard
            let bundleId = Bundle.main.bundleIdentifier,
            let redirectURL = URL(string: "\(bundleId)://auth")
        else { throw Web3AuthError.noBundleIdentifierFound }
        w3ALoginParams = loginParams
        // assign loginParams redirectUrl from intiParamas redirectUrl
        w3ALoginParams?.redirectUrl = "\(bundleId)://auth"
        if let loginConfig = initParams.loginConfig?.values.first,
           let savedDappShare = KeychainManager.shared.getDappShare(verifier: loginConfig.verifier) {
            w3ALoginParams?.dappShare = savedDappShare
        }

        let sdkUrlParams = SdkUrlParams(options: initParams, params: w3ALoginParams!, actionType: "login")

        let loginId = try await getLoginId(data: sdkUrlParams)

        let jsonObject: [String: String?] = [
            "loginId": loginId,
        ]

        let url = try Web3Auth.generateAuthSessionURL(initParams: initParams, jsonObject: jsonObject, sdkUrl: initParams.sdkUrl?.absoluteString, path: "start")

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Web3AuthState, Error>) in

            authSession = ASWebAuthenticationSession(
                url: url, callbackURLScheme: redirectURL.scheme) { callbackURL, authError in

                    guard
                        authError == nil,
                        let callbackURL = callbackURL,
                        let sessionResponse = try? Web3Auth.decodeStateFromCallbackURL(callbackURL)
                    else {
                        let authError = authError ?? Web3AuthError.unknownError
                        if case ASWebAuthenticationSessionError.canceledLogin = authError {
                            continuation.resume(throwing: Web3AuthError.userCancelled)
                        } else {
                            continuation.resume(throwing: authError)
                        }
                        return
                    }

                    let sessionId = sessionResponse.sessionId
                    self.sessionManager.setSessionId(sessionId: sessionId)
                    SessionManager.saveSessionIdToStorage(sessionId)

                    Task {
                        do {
                            let loginDetails = try await self.getLoginDetails(callbackURL)
                            if let safeUserInfo = loginDetails.userInfo {
                                KeychainManager.shared.saveDappShare(userInfo: safeUserInfo)
                            }

                            self.state = loginDetails
                            return continuation.resume(returning: loginDetails)
                        } catch {
                            continuation.resume(throwing: Web3AuthError.unknownError)
                        }
                    }
                }

            self.authSession?.presentationContextProvider = self

            if !(self.authSession?.start() ?? false) {
                continuation.resume(throwing: Web3AuthError.unknownError)
            }
        })
    }

    public func enableMFA(_ loginParams: W3ALoginParams? = nil) async throws -> Bool {
        if state?.userInfo?.isMfaEnabled == true {
            throw Web3AuthError.mfaAlreadyEnabled
        }
        let sessionId = sessionManager.getSessionId()
        if !sessionId.isEmpty {
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let redirectURL = URL(string: "\(bundleId)://auth")
            else { throw Web3AuthError.noBundleIdentifierFound }

            var extraLoginOptions: ExtraLoginOptions? = ExtraLoginOptions()
            if loginParams?.extraLoginOptions != nil {
                extraLoginOptions = loginParams?.extraLoginOptions
            } else {
                extraLoginOptions = w3ALoginParams?.extraLoginOptions
            }
            extraLoginOptions?.login_hint = state?.userInfo?.verifierId

            let jsonData = try? JSONEncoder().encode(extraLoginOptions)
            let _extraLoginOptions = String(data: jsonData!, encoding: .utf8)

            let params: [String: String?] = [
                "loginProvider": state?.userInfo?.typeOfLogin,
                "mfaLevel": MFALevel.MANDATORY.rawValue,
                "redirectUrl": redirectURL.absoluteString,
                "extraLoginOptions": _extraLoginOptions,
            ]

            let setUpMFAParams = SetUpMFAParams(options: initParams, params: params, actionType: "enable_mfa", sessionId: sessionId)
            let loginId = try await getLoginId(data: setUpMFAParams)

            let jsonObject: [String: String?] = [
                "loginId": loginId,
            ]

            let url = try Web3Auth.generateAuthSessionURL(initParams: initParams, jsonObject: jsonObject, sdkUrl: initParams.sdkUrl?.absoluteString, path: "start")

            return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Bool, Error>) in

                authSession = ASWebAuthenticationSession(
                    url: url, callbackURLScheme: redirectURL.scheme) { callbackURL, authError in

                        guard
                            authError == nil,
                            let callbackURL = callbackURL,
                            let sessionResponse = try? Web3Auth.decodeStateFromCallbackURL(callbackURL)
                        else {
                            let authError = authError ?? Web3AuthError.unknownError
                            if case ASWebAuthenticationSessionError.canceledLogin = authError {
                                continuation.resume(throwing: Web3AuthError.userCancelled)
                            } else {
                                continuation.resume(throwing: authError)
                            }
                            return
                        }

                        let sessionId = sessionResponse.sessionId
                        self.sessionManager.setSessionId(sessionId: sessionId)
                        SessionManager.saveSessionIdToStorage(sessionId)

                        Task {
                            do {
                                let loginDetails = try await self.getLoginDetails(callbackURL)
                                if let safeUserInfo = loginDetails.userInfo {
                                    KeychainManager.shared.saveDappShare(userInfo: safeUserInfo)
                                }
                                self.state = loginDetails
                                return continuation.resume(returning: true)
                            } catch {
                                continuation.resume(throwing: Web3AuthError.unknownError)
                            }
                        }
                    }
                authSession?.presentationContextProvider = self

                if !(authSession?.start() ?? false) {
                    continuation.resume(throwing: Web3AuthError.unknownError)
                }
            })
        } else {
            throw Web3AuthError.runtimeError("SessionId not found. Please login first.")
        }
    }

    public func launchWalletServices(chainConfig: ChainConfig, path: String? = "wallet") async throws {
        let sessionId = SessionManager.getSessionIdFromStorage()!
        if !sessionId.isEmpty {
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let _ = URL(string: "\(bundleId)://auth")
            else { throw Web3AuthError.noBundleIdentifierFound }

            initParams.chainConfig = chainConfig
            let walletServicesParams = WalletServicesParams(options: initParams, appState: nil)

            let loginId = try await getLoginId(data: walletServicesParams)

            let jsonObject: [String: String?] = [
                "loginId": loginId,
                "sessionId": sessionId,
                "platform": "ios",
            ]

            let url = try Web3Auth.generateAuthSessionURL(initParams: initParams, jsonObject: jsonObject, sdkUrl: initParams.walletSdkUrl?.absoluteString, path: path)
            // open url in webview
            await UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController?.present(webViewController, animated: true, completion: nil)
            await webViewController.webView.load(URLRequest(url: url))
        } else {
            throw Web3AuthError.runtimeError("SessionId not found. Please login first.")
        }
    }

    public func request(chainConfig: ChainConfig, method: String, requestParams: [Any], path: String? = "wallet/request", appState: String? = nil) async throws -> SignResponse {
        let sessionId = SessionManager.getSessionIdFromStorage()!
        if !sessionId.isEmpty {
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let _ = URL(string: "\(bundleId)://auth")
            else { throw Web3AuthError.noBundleIdentifierFound }
            initParams.chainConfig = chainConfig

            let walletServicesParams = WalletServicesParams(options: initParams, appState: appState)

            let loginId = try await getLoginId(data: walletServicesParams)

            var signMessageMap: [String: String] = [:]
            signMessageMap["loginId"] = loginId
            signMessageMap["sessionId"] = sessionId
            signMessageMap["platform"] = "ios"

            var requestData: [String: Any] = [:]
            requestData["method"] = method
            requestData["params"] = try? JSONSerialization.jsonObject(with: JSONSerialization.data(withJSONObject: requestParams), options: []) as? [Any]

            if let requestDataJson = try? JSONSerialization.data(withJSONObject: requestData, options: []),
               let requestDataJsonString = String(data: requestDataJson, encoding: .utf8) {
                // Add the requestData JSON string to signMessageMap as a property
                signMessageMap["request"] = requestDataJsonString
            }

            let url = try Web3Auth.generateAuthSessionURL(initParams: initParams, jsonObject: signMessageMap, sdkUrl: initParams.walletSdkUrl?.absoluteString, path: path)

            // open url in webview
            return await withCheckedContinuation { continuation in
                Task {
                    let webViewController = await MainActor.run {
                        WebViewController(redirectUrl: initParams.redirectUrl, onSignResponse: { signResponse in
                            continuation.resume(returning: signResponse)
                        })
                    }

                    DispatchQueue.main.async {
                        UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController?.present(webViewController, animated: true) {
                            webViewController.webView.load(URLRequest(url: url))
                        }
                    }
                }
            }
        } else {
            throw Web3AuthError.runtimeError("SessionId not found. Please login first.")
        }
    }

    static func generateAuthSessionURL(initParams: W3AInitParams, jsonObject: [String: String?], sdkUrl: String?, path: String?) throws -> URL {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting.insert(.sortedKeys)

        guard
            let data = try? jsonEncoder.encode(jsonObject),
            // Using sorted keys to produce consistent results
            var components = URLComponents(string: sdkUrl ?? "")
        else {
            throw Web3AuthError.encodingError
        }
        components.path = components.path + "/" + path!
        components.fragment = "b64Params=" + data.toBase64URL()

        guard let url = components.url
        else {
            throw Web3AuthError.runtimeError("Invalid URL")
        }

        return url
    }

    static func decodeStateFromCallbackURL(_ callbackURL: URL) throws -> SessionResponse {
        // Update here is needed
        guard
            let host = callbackURL.host,
            let fragment = callbackURL.fragment,
            let component = URLComponents(string: host + "?" + fragment),
            let queryItems = component.queryItems,
            let b64ParamsItem = queryItems.first(where: { $0.name == "b64Params" }),
            let callbackFragment = b64ParamsItem.value,
            let callbackData = Data.fromBase64URL(callbackFragment),
            let callbackState = try? JSONDecoder().decode(SessionResponse.self, from: callbackData)
        else {
            throw Web3AuthError.decodingError
        }
        return callbackState
    }

    static func decodeSessionStringfromCallbackURL(_ callbackURL: URL) throws -> String? {
        let callbackFragment = callbackURL.fragment
        return callbackFragment?.components(separatedBy: "&")[0].components(separatedBy: "=")[1]
    }

    public func fetchProjectConfig() async throws -> Bool {
        var response: Bool = false
        let api = Router.get([.init(name: "project_id", value: initParams.clientId), .init(name: "network", value: initParams.network.rawValue), .init(name: "whitelist", value: "true")])
        let result = await Service.request(router: api)
        switch result {
        case let .success(data):
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(ProjectConfigResponse.self, from: data)
                // os_log("fetchProjectConfig API response is: %@", log: getTorusLogger(log: Web3AuthLogger.network, type: .info), type: .info, "\(String(describing: result))")
                initParams.originData = result.whitelist.signedUrls.merging(initParams.originData ?? [:]) { _, new in new }
                if let whiteLabelData = result.whiteLabelData {
                    if initParams.whiteLabel == nil {
                        initParams.whiteLabel = whiteLabelData
                    } else {
                        initParams.whiteLabel = initParams.whiteLabel?.merge(with: whiteLabelData)
                    }
                }
                response = true
            } catch {
                throw error
            }
        case let .failure(error):
            throw error
        }
        return response
    }

    public func getPrivkey() -> String {
        if state == nil {
            return ""
        }
        let privKey: String = initParams.useCoreKitKey == true ? state?.coreKitKey ?? "" : state?.privKey ?? ""
        return privKey
    }

    public func getEd25519PrivKey() -> String {
        if state == nil {
            return ""
        }
        let ed25519Key: String = initParams.useCoreKitKey == true ?
            state?.coreKitEd25519PrivKey ?? "" : state?.ed25519PrivKey ?? ""
        return ed25519Key
    }

    public func getUserInfo() throws -> Web3AuthUserInfo {
        guard let state = state, let userInfo = state.userInfo else { throw Web3AuthError.noUserFound }
        return userInfo
    }

    public func getWeb3AuthResponse() throws -> Web3AuthState {
        guard let state = state else {
            throw Web3AuthError.noUserFound
        }
        return state
    }
    
    public func registerPasskey(
        authenticatorAttachment: AuthenticatorAttachment? = nil,
        username: String? = nil,
        rp: Rp
    ) async throws -> Bool {
        let registrationOptionsRes = try await getRegistrationOptions(authenticatorAttachment: authenticatorAttachment, username: username, rp: rp)
        signInWithPasskey(registrationResponse: registrationOptionsRes)
        return true
    }
    
    func loginWithPasskey(authenticatorId: String? = nil) async throws {
        let loginResult = try await loginUser(authenticatorId: authenticatorId)
    }
    
    func loginUser(authenticatorId: String? = nil) async throws {
        let data = try await getAuthenticationOptions(authenticatorId: authenticatorId ?? "", rpId: rpId!)
        // Assign tracking ID
        self.trackingId = data.trackingId
        let options = data.options
        loginWithExistingPasskey(challenge: data.options.challenge)
    }
    
    public func getRegistrationOptions(authenticatorAttachment: AuthenticatorAttachment? = nil,
                                       username: String? = nil,
                                       rp: Rp) async throws  -> RegistrationResponse {
        self.rpId = rp.id
        Router.baseURL = PASSKEY_SVC_URL[initParams.buildEnv!] ?? ""
        let requestBody = RegistrationOptionsRequest(
            web3auth_client_id: initParams.clientId,
            verifier_id: state?.userInfo?.verifierId ?? "",
            verifier: state?.userInfo?.verifier ?? "",
            rp: Rp(name: rp.name, id: rp.id),
            username: username?.isEmpty ?? true ? state?.userInfo?.name ?? "" : username ?? "",
            network: initParams.network.rawValue,
            signatures: state?.signatures ?? []
        )
        let api = Router.getRegistrationOptions(T: requestBody)
        let result = await Service.request(router: api)
        switch result {
        case let .success(data):
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(RegistrationResponse.self, from: data)
                self.trackingId = result.data.trackingId
                return result
            } catch {
                throw error
            }
        case let .failure(error):
            throw error
        }
    }
    
    private func signInWithPasskey(registrationResponse: RegistrationResponse) {
        if #available(iOS 15.0, *) {
            let optionsData = registrationResponse.data.options
            let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "web3auth.io")
            let platformKeyRequest = platformProvider.createCredentialRegistrationRequest(challenge: optionsData.challenge.data(using: .utf8)!, name: optionsData.user.name,
                userID: optionsData.user.id.data(using: .utf8)!)
            let authorizationController = ASAuthorizationController(authorizationRequests: [platformKeyRequest])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    private func loginWithExistingPasskey(challenge: String) {
        if #available(iOS 15.0, *) {
            let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "web3auth.io")
            let platformKeyRequest = platformProvider.createCredentialAssertionRequest(challenge: challenge.data(using: .utf8)!)
            let authorizationController = ASAuthorizationController(authorizationRequests: [platformKeyRequest])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if #available(iOS 15.0, *) {
            if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
                print("Authorized with Passkey: \(credential.rawClientDataJSON)")
                print("Authorized with Passkeys: Create account with credential ID = \(credential.credentialID)")
                Task {
                    do {
                        print("A new passkey was registered: \(credential)")
                        credential.credentialID
                        guard let attestationObject = credential.rawAttestationObject?.base64EncodedString() else { return }
                        let clientDataJSON = credential.rawClientDataJSON.base64EncodedString()
                        let credentialID = credential.credentialID.base64EncodedString()
                        
                        do {
                            // Decode the raw attestation object
            
                            let cborDecoder = CborDecoder()
                            let decodedObject = try cborDecoder.decode(AnyDecodable.self, from: credential.rawAttestationObject!)
                            
                            // Extract the authenticatorData
                            /*if let authenticatorData = decodedObject["authData"] as? Data {
                                // ... (process authenticatorData as needed)
                            }
                            
                            // Extract the public key data (simplified example)
                            // Note: This is a simplified example and may require more complex decoding based on the specific CBOR structure.
                            if let publicKeyData = decodedObject["publicKey"] as? Data {
                                // ... (process publicKeyData as needed)
                            }*/
                        } catch {
                            print("Error decoding attestation object: \(error)")
                        }
                        
                        do {
                            let attestation = try decodeAttestationObject((attestationObject))
                            let authData = attestation.authData // Now you can access the authData
                            print("Auth Data: \(authData)")
                        } catch {
                            print("Error decoding attestation object: \(error.localizedDescription)")
                        }
                        
                        let passkeyVerifierId = try getPasskeyVerifierId(verificationResponse: credential)
                        
                        let passkeyPublicKey = try await getPasskeyPublicKey(verifier: state?.userInfo?.verifier ?? "", verifierId: passkeyVerifierId)
                        let encryptedMetadata = try getEncryptedMetadata(passkeyPubKey: passkeyPublicKey)
                        
                        let registrationJson = RegistrationResponseJson(
                            rawId: credential.credentialID.base64EncodedString(),
                            id: credential.credentialID.base64EncodedString(),
                            response: Response(clientDataJSON: clientDataJSON,
                                               attestationObject: attestationObject,
                                               transports: ["internal","hybrid"], authenticatorData: "",
                                               publicKeyAlgorithm: -7,
                                               publicKey: ""),
                            clientExtensionResults: ClientExtensionResults(credProps: CredProps(rk: true))
                        )
                        
                        
                        let verificationResult = try await verifyRegistration(registrationResponse: registrationJson, signatures: (state?.signatures)!, passkeyToken: (state?.userInfo?.idToken)!, data: encryptedMetadata ?? "")
                    } catch {
                        // Handle any errors from async code
                        print("Error: \(error)")
                    }
                }
                
            } else if let credentialAssertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
                //showAlert(with: "Authorized with Passkeys", message: "Sign in with credential ID = \(credential.credentialID)")
                //let signature = credential.signature
                //let clientDataJSON = credential.rawClientDataJSON
                Task {
                    do {
                        //Steps to verify the challenge by sending it to your server tio verify
                        let result = try await verifyAuthentication(publicKeyCredential: credentialAssertion)
                        print("Authentication response: \(credentialAssertion.rawAuthenticatorData.hexString)")
                        // Return the parsed login data
                        let loginData = LoginData(
                            authenticationResponse: credentialAssertion,
                            data: AuthenticationData(
                                challenge_timestamp: result.data!.challenge_timestamp,
                                transports: result.data!.transports,
                                credential_public_key: result.data!.credential_public_key,
                                rpId: result.data!.rpID,
                                id_token: result.data!.id_token,
                                metadata:result.data!.metadata,
                                verifier_id: result.data!.verifier_id
                            )
                        )
                        
                        let authenticationResponse = loginData.authenticationResponse
                        
                        let signature = authenticationResponse.signature.hexString
                        let clientDataJSON = authenticationResponse.rawClientDataJSON
                        let authenticatorData = authenticationResponse.rawAuthenticatorData
                        let id = authenticationResponse.userID
                        
                        let data = loginData.data
                        
                        let publicKey = data.credential_public_key
                        let challenge = data.challenge_timestamp
                        let metadata = data.metadata
                        let verifierId = data.verifier_id
                        
                        // Create loginParams
                        let passKeyloginParams = PassKeyLoginParams(
                            verifier: passkeysVerifierMap[initParams.network] ?? "sapphire_mainnet",
                            verifierId: verifierId,
                            idToken: signature,
                            extraVerifierParams: ExtraVerifierParams(
                                signature: signature,
                                clientDataJSON: clientDataJSON.base64EncodedString(),
                                authenticatorData: (authenticatorData?.base64EncodedString())!,
                                publicKey: publicKey,
                                challenge: challenge,
                                rpOrigin: "https://your-origin.com",
                                rpId: rpId!,
                                credId: (id?.base64EncodedString())!
                            )
                        )
                        
                        let passkey = try await getPasskeyPostboxKey(passKeyLoginParams: passKeyloginParams)
                        // TODO()
                        //let decryptedData: MetadataInfo = try decryptData(passkey: passkey, metadata: metadata)
                        //if decryptedData.privKey.isEmpty { throw Web3AuthError.metadataDecryptionFailed }
                        
                    } catch {
                        // Handle any errors from async code
                        print("Error: \(error)")
                    }
                }
            } else {
                //showAlert(with: "Authorized", message: "e.g. with \"Sign in with Apple\"")
                // Handle other authentication cases, such as Sign in with Apple.
            }
        } else {
            print("No support for iOS version less than 16")
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Authorization failed: \(error.localizedDescription)")
    }
    
    func decodeAttestationObject(_ attestationObject: String) throws -> AttestationObject {
        guard let data = base64URLStringToData(attestationObject) else {
            throw NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Base64 URL string"])
        }
        
        // Step 3: Use the correct type in the decode method
        let decoder = CborDecoder()
        let attestationStruct: AttestationObject = try decoder.decode(AttestationObject.self, from: data)
        
        return attestationStruct
    }
    
    struct AttestationObject: Decodable {
        let authData: Data // Assuming authData is stored as Data
    }
    
    func base64URLStringToBuffer(_ base64UrlString: String) -> Data? {
        // Replace URL-safe characters to Base64 characters
        var base64String = base64UrlString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if necessary (Base64 requires the string length to be a multiple of 4)
        let paddingLength = base64String.count % 4
        if paddingLength > 0 {
            base64String.append(String(repeating: "=", count: 4 - paddingLength))
        }
        
        if let data = Data(base64Encoded: base64String) {
            print("Decoded Data (hex): \(data.map { String(format: "%02x", $0) }.joined())")
            print("Decoded Data (string): \(String(data: data, encoding: .utf8) ?? "Invalid UTF-8 string")")
            return data
        } else {
            print("Failed to decode Base64 URL string")
            return nil
        }
    }
    
    @available(iOS 15.0, *)
    func getPasskeyVerifierId(verificationResponse: ASAuthorizationPlatformPublicKeyCredentialRegistration) throws -> String {
        let attestationObjectData = verificationResponse.rawAttestationObject?.base64EncodedString()
        let attestationStruct = try decodeAttestationObject(attestationObjectData!)
        let authDataStruct = try parseAuthData(attestationStruct.authData)
        // Get COSEPublicKey and encode it as base64url
        print("authDataStruct COSEPublicKey in String", authDataStruct.COSEPublicKey.base64EncodedString())
        let base64UrlString = b64toString(authDataStruct.COSEPublicKey)
        // Compute verifierId using keccak256
        let verifierId = try computeVerifierId(base64UrlString)
        return verifierId
    }
    
    func getPasskeyPublicKey(verifier: String, verifierId: String) async throws -> TorusPublicKey {
        do {
            let nodeDetailManager = NodeDetailManager(network: WEB3AUTH_NETWORK_MAP[Network(rawValue: initParams.network.rawValue) ?? Network.sapphire_mainnet]!)
            let fnd = try await nodeDetailManager.getNodeDetails(verifier: verifier, verifierID: verifierId)
            
            let torusUtils = try! TorusUtils(params: TorusOptions(clientId: initParams.clientId, network: WEB3AUTH_NETWORK_MAP[Network(rawValue: initParams.network.rawValue) ?? Network.sapphire_mainnet]!, enableOneKey: true))
            let data = try await torusUtils.getPublicAddress(endpoints: fnd.getTorusNodeEndpoints(), verifier: verifier, verifierId: verifierId)
            return data
        } catch {
            print("Error fetching passkey public key: \(error)")
            throw error
        }
    }
    
    func getEncryptedMetadata(passkeyPubKey: TorusPublicKey) throws -> String? {
        let userInfo = try getUserInfo()
        
        let metadata = MetadataInfo(
            privKey: getPrivkey(),
            userInfo: userInfo
        )
        
        // Convert metadata to JSON string
        guard let jsonData = try? JSONEncoder().encode(metadata),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return try encryptData(
            x: passkeyPubKey.finalKeyData?.X ?? "",
            y: passkeyPubKey.finalKeyData?.Y ?? "",
            data: jsonString
        )
    }
        
    private func encryptData(x: String, y: String, data: String) throws -> String {
        let nodePub = KeyUtils.getPublicKeyFromCoords(pubKeyX: x, pubKeyY: y)
        let nodePubKey = try PublicKey(hex: nodePub).serialize(compressed: true)
        let ecies = try EncryptionUtils.encrypt(publicKey: nodePubKey, msg: data)
        let data = try JSONEncoder().encode(ecies)
        return String(data: data, encoding: .utf8)!
    }
    
    private func decryptData(data: ECIES, privKey: String) throws -> String {
        let decrypted = try EncryptionUtils.decrypt(privateKey: privKey, opts: data)
        let data = try JSONEncoder().encode(decrypted)
        return String(data: data, encoding: .utf8)!
    }
    
    private func verifyRegistration(
        registrationResponse: RegistrationResponseJson,
        signatures: [String], passkeyToken: String, data: String
    ) async throws -> ChallengeData {
        Router.baseURL = PASSKEY_SVC_URL[initParams.buildEnv!] ?? ""
        let requestBody = VerifyRequest(
            web3auth_client_id: initParams.clientId,
            tracking_id: self.trackingId!,
            verification_data: registrationResponse,
            network: initParams.network.rawValue,
            signatures: signatures,
            metadata: data
        )
        let api = Router.verifyRegistration(T: requestBody)
        let result = await Service.request(router: api)
        switch result {
        case let .success(data):
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(VerifyRegistrationResponse.self, from: data)
                return result.data!
            } catch {
                throw error
            }
        case let .failure(error):
            throw error
        }
    }
    
    private func getAuthenticationOptions(authenticatorId: String, rpId: String) async throws -> AuthenticationOptionsData {
        Router.baseURL = PASSKEY_SVC_URL[initParams.buildEnv!] ?? ""
        let requestBody = AuthenticationOptionsRequest(
            web3authClientId: initParams.clientId,
            rpId: rpId,
            authenticatorId: authenticatorId,
            network: initParams.network.rawValue
        )
        let api = Router.getAuthenticationOptions(T: requestBody)
        let result = await Service.request(router: api)
        switch result {
        case let .success(data):
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(AuthenticationOptionsResponse.self, from: data)
                return result.data
            } catch {
                throw error
            }
        case let .failure(error):
            throw error
        }
    }
    
    @available(iOS 15.0, *)
    private func verifyAuthentication(publicKeyCredential: ASAuthorizationPlatformPublicKeyCredentialAssertion) async throws -> VerifyAuthenticationResponse {
        Router.baseURL = PASSKEY_SVC_URL[initParams.buildEnv!] ?? ""
        let requestBody = VerifyAuthenticationRequest(
            web3authClientId: initParams.clientId,
            trackingId: self.trackingId!,
            verificationData: publicKeyCredential.rawAuthenticatorData,
            network: initParams.network.rawValue
        )
        let api = Router.verifyAuthentication(T: requestBody)
        let result = await Service.request(router: api)
        switch result {
        case let .success(data):
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(VerifyAuthenticationResponse.self, from: data)
                return result
            } catch {
                throw error
            }
        case let .failure(error):
            throw error
        }
    }
    
    func b64toString(_ data: Data) -> String {
        return data.base64EncodedString()
    }
    
    func base64URLStringToData(_ base64UrlString: String) -> Data? {
        var base64 = base64UrlString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 += "="
        }
        return Data(base64Encoded: base64)
    }
    
    func decodeCBORData(_ data: Data) throws -> [String: Any] {
        // Decode the data as a generic Decodable type
        let decodedData = try CborDecoder().decode(AnyDecodable.self, from: data)
        
        // Convert the decoded data to a dictionary of [String: Any] if possible
        guard let decodedDict = decodedData.value as? [String: Any] else {
            throw Web3AuthError.runtimeError("Invalid Data")
        }
        
        return decodedDict
    }
    
    struct AnyDecodable: Decodable {
        let value: Any
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                value = string
            } else if let int = try? container.decode(Int.self) {
                value = int
            } else if let double = try? container.decode(Double.self) {
                value = double
            } else if let bool = try? container.decode(Bool.self) {
                value = bool
            } else {
                throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode AnyDecodable"))
            }
        }
    }
    
    func computeVerifierId(_ base64UrlString: String) throws -> String {
        let data = Data(base64Encoded: base64UrlString)
        let hash = try data?.sha3(varient: .KECCAK256)
        return b64toString(hash!)
    }
    
    func parseAuthData(_ paramBuffer: Data) throws -> AuthParamsData {
        var buffer = paramBuffer
        
        // Read rpIdHash (32 bytes)
        let rpIdHash = buffer.prefix(32)
        buffer = buffer.dropFirst(32)
        
        // Read flags (1 byte)
        let flagsBuf = buffer.prefix(1)
        buffer = buffer.dropFirst(1)
        
        guard let flagsInt = flagsBuf.first else {
            throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse flags"])
        }
        
        let flags = AuthParamsData.Flags(
            up: (flagsInt & 0x01) != 0,
            uv: (flagsInt & 0x04) != 0,
            at: (flagsInt & 0x40) != 0,
            ed: (flagsInt & 0x80) != 0,
            flagsInt: flagsInt
        )
        
        // Read counter (4 bytes)
        var counterBuf = buffer.prefix(4)
        buffer = buffer.dropFirst(4)
        
        // Read counter safely
        let counter = readUInt32BE(from: &counterBuf)
        
        // Check if the at flag is set
        guard flags.at else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to parse auth data"])
        }
        
        // Read aaguid (16 bytes)
        let aaguid = buffer.prefix(16)
        buffer = buffer.dropFirst(16)
        
        // Read credID length (2 bytes)
        var credIDLenBuf = buffer.prefix(2)
        buffer = buffer.dropFirst(2)
        
        // Read credID length safely
        let credIDLen = readUInt16BE(from: &credIDLenBuf)
        
        // Read credID based on length
        let credID = buffer.prefix(Int(credIDLen))
        buffer = buffer.dropFirst(Int(credIDLen))
        
        // Remaining buffer is the COSEPublicKey
        let COSEPublicKey = buffer
        
        return AuthParamsData(rpIdHash: rpIdHash, flagsBuf: flagsBuf, flags: flags, counter: counter, counterBuf: counterBuf, aaguid: aaguid, credID: credID, COSEPublicKey: COSEPublicKey)
    }
    
    func readUInt32BE(from buffer: inout Data) -> UInt32 {
        guard buffer.count >= 4 else {
            fatalError("Buffer does not contain enough bytes to read a UInt32")
        }
        
        let counterBytes = Array(buffer.prefix(4))
        buffer = buffer.dropFirst(4)
        
        return UInt32(counterBytes[0]) << 24 |
        UInt32(counterBytes[1]) << 16 |
        UInt32(counterBytes[2]) << 8  |
        UInt32(counterBytes[3])
    }
    
    func readUInt16BE(from buffer: inout Data) -> UInt16 {
        guard buffer.count >= 2 else {
            fatalError("Buffer does not contain enough bytes to read a UInt16")
        }
        
        let lengthBytes = Array(buffer.prefix(2))
        buffer = buffer.dropFirst(2)
        
        return UInt16(lengthBytes[0]) << 8 | UInt16(lengthBytes[1])
    }
    
    private func getPasskeyPostboxKey(passKeyLoginParams: PassKeyLoginParams) async throws-> String {
        do {
            let nodeDetailManager = NodeDetailManager(network: WEB3AUTH_NETWORK_MAP[Network(rawValue: initParams.network.rawValue) ?? Network.sapphire_mainnet]!)
            let fnd = try await nodeDetailManager.getNodeDetails(verifier: passKeyLoginParams.verifier, verifierID: passKeyLoginParams.verifierId)
            
            let torusUtils = try! TorusUtils(params: TorusOptions(clientId: initParams.clientId, network: WEB3AUTH_NETWORK_MAP[Network(rawValue: initParams.network.rawValue) ?? Network.sapphire_mainnet]!, enableOneKey: true))
            let data = try await torusUtils.retrieveShares(endpoints: fnd.getTorusNodeEndpoints(), verifier: passKeyLoginParams.verifier,
                                                           verifierParams: VerifierParams(verifier_id: passKeyLoginParams.verifierId), idToken: passKeyLoginParams.idToken)
            return data.finalKeyData.privKey
        } catch {
            print("Error fetching passkey private key: \(error)")
            throw error
        }
    }
}

extension Web3Auth: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
