import AuthenticationServices
import OSLog
import SessionManager
import FetchNodeDetails
import TorusUtils
import Foundation

/**
 Authentication using Web3Auth.
 */

public class Web3Auth: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var initParams: W3AInitParams
    private var authSession: ASWebAuthenticationSession?
    // You can check the state variable before logging the user in, if the user
    // has an active session the state variable will already have all the values you 
    // get from login so the user does not have to re-login
    public var state: Web3AuthState?
    var sessionManager: SessionManager
    var webViewController: WebViewController = DispatchQueue.main.sync{ WebViewController() }
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
            .sapphire_devnet: "https://signer.web3auth.io"
    ]
    
    let PASSKEY_SVC_URL: [BuildEnv: String] = [
        .testing: "https://api-develop-passwordless.web3auth.io",
        .staging: "https://api-passwordless.web3auth.io",
        .production: "https://api-passwordless.web3auth.io"
    ]
    
    let WEB3AUTH_NETWORK_MAP: [Network: TorusNetwork] = [
        .mainnet: TorusNetwork.legacy(LegacyNetwork.MAINNET),
        .testnet: TorusNetwork.legacy(LegacyNetwork.TESTNET),
        .aqua: TorusNetwork.legacy(LegacyNetwork.AQUA),
        .cyan: TorusNetwork.legacy(LegacyNetwork.CYAN),
        .sapphire_devnet: TorusNetwork.sapphire(SapphireNetwork.SAPPHIRE_DEVNET),
        .sapphire_mainnet: TorusNetwork.sapphire(SapphireNetwork.SAPPHIRE_MAINNET)
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
        sessionManager = .init()
        super.init()
        do {
            let fetchConfigResult = try await fetchProjectConfig()
            if(fetchConfigResult) {
                do {
                    let loginDetailsDict = try await sessionManager.authorizeSession()
                    guard let loginDetails = Web3AuthState(dict: loginDetailsDict, sessionID: sessionManager.getSessionID() ?? "",
                    network: initParams.network) else { throw Web3AuthError.decodingError }
                    state = loginDetails
                } catch let error {
                    os_log("%s", log: getTorusLogger(log: Web3AuthLogger.core, type: .error), type: .error, error.localizedDescription)
                }
            }
        } catch let error {
            os_log("%s", log: getTorusLogger(log: Web3AuthLogger.core, type: .error), type: .error, error.localizedDescription)
            throw error
        }
    }

    public func logout() async throws {
        guard let state = state else {throw Web3AuthError.noUserFound}
        let _ = try await sessionManager.invalidateSession()
        if let verifer = state.userInfo?.verifier, let dappShare = KeychainManager.shared.getDappShare(verifier: verifer) {
            KeychainManager.shared.delete(key: .custom(dappShare))
        }
        self.state = nil
    }
    
    public func getLoginId<T: Encodable>(data: T) async throws -> String? {
        return try await sessionManager.createSession(data: data)
    }
    
    private func getLoginDetails(_ callbackURL: URL) async throws -> Web3AuthState {
        let loginDetailsDict = try await sessionManager.authorizeSession()
        guard
            let loginDetails = Web3AuthState(dict: loginDetailsDict, sessionID: sessionManager.getSessionID() ?? "",network: initParams.network)
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
        //assign loginParams redirectUrl from intiParamas redirectUrl
        w3ALoginParams?.redirectUrl = "\(bundleId)://auth"
        if let loginConfig = initParams.loginConfig?.values.first,
           let savedDappShare = KeychainManager.shared.getDappShare(verifier: loginConfig.verifier) {
            w3ALoginParams?.dappShare = savedDappShare
        }
        
        let sdkUrlParams = SdkUrlParams(options: initParams, params: w3ALoginParams!, actionType: "login")

        let loginId = try await getLoginId(data: sdkUrlParams)
        
        let jsonObject: [String: String?] = [
            "loginId": loginId
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
                    
                    self.sessionManager.setSessionID(sessionResponse.sessionId)
                    Task {
                        do {
                            let loginDetails = try await self.getLoginDetails(callbackURL)
                            if let safeUserInfo = loginDetails.userInfo {
                                KeychainManager.shared.saveDappShare(userInfo: safeUserInfo)
                            }
                            self.sessionManager.setSessionID(loginDetails.sessionId ?? "")

                            self.state = loginDetails
                            return continuation.resume(returning: loginDetails)
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
    }
    
    public func enableMFA(_ loginParams: W3ALoginParams? = nil) async throws -> Bool{
        if(state?.userInfo?.isMfaEnabled == true) {
            throw Web3AuthError.mfaAlreadyEnabled
        }
        let sessionId = self.sessionManager.getSessionID()
        if !(sessionId ?? "").isEmpty {
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let redirectURL = URL(string: "\(bundleId)://auth")
            else { throw Web3AuthError.noBundleIdentifierFound }
            
            var extraLoginOptions: ExtraLoginOptions? = ExtraLoginOptions()
            if(loginParams?.extraLoginOptions != nil) {
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
                "extraLoginOptions" : _extraLoginOptions
            ]
            
            let setUpMFAParams = SetUpMFAParams(options: initParams, params: params, actionType: "enable_mfa", sessionId: sessionId ?? "")
            
            let _sessionId = sessionManager.getSessionID() ?? ""
            let loginId = try await getLoginId(data: setUpMFAParams)
            self.sessionManager.setSessionID(_sessionId)
            
            let jsonObject: [String: String?] = [
                "loginId": loginId
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
                        
                        self.sessionManager.setSessionID(sessionResponse.sessionId)
                        Task {
                            do {
                                let loginDetails = try await self.getLoginDetails(callbackURL)
                                if let safeUserInfo = loginDetails.userInfo {
                                    KeychainManager.shared.saveDappShare(userInfo: safeUserInfo)
                                }
                                self.sessionManager.setSessionID(loginDetails.sessionId ?? "")
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
        }
        else {
            throw Web3AuthError.runtimeError("SessionId not found. Please login first.")
        }
    }
    
    public func launchWalletServices(chainConfig: ChainConfig, path: String? = "wallet") async throws {
        let sessionId = self.sessionManager.getSessionID()
        if !(sessionId ?? "").isEmpty {
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let _ = URL(string: "\(bundleId)://auth")
            else { throw Web3AuthError.noBundleIdentifierFound }
            
            initParams.chainConfig = chainConfig
            let walletServicesParams = WalletServicesParams(options: initParams)
            
            let _sessionId = sessionManager.getSessionID() ?? ""
            let loginId = try await getLoginId(data: walletServicesParams)
            self.sessionManager.setSessionID(_sessionId)
    
            let jsonObject: [String: String?] = [
                "loginId": loginId,
                "sessionId": sessionId,
                "platform": "ios"
            ]
            
            let url = try Web3Auth.generateAuthSessionURL(initParams: initParams, jsonObject: jsonObject, sdkUrl: initParams.walletSdkUrl?.absoluteString, path: path)
            //open url in webview
            await UIApplication.shared.keyWindow?.rootViewController?.present(webViewController, animated: true, completion: nil)
            await webViewController.webView.load(URLRequest(url: url))
        }
        else {
            throw Web3AuthError.runtimeError("SessionId not found. Please login first.")
        }
    }
    
    public func request(chainConfig: ChainConfig, method: String, requestParams: [Any], path: String? = "wallet/request") async throws {
        let sessionId = self.sessionManager.getSessionID()
        if !(sessionId ?? "").isEmpty {
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let _ = URL(string: "\(bundleId)://auth")
            else { throw Web3AuthError.noBundleIdentifierFound }
            initParams.chainConfig = chainConfig
            
            let walletServicesParams = WalletServicesParams(options: initParams)
            
            let _sessionId = sessionManager.getSessionID() ?? ""
            let loginId = try await getLoginId(data: walletServicesParams)
            self.sessionManager.setSessionID(_sessionId)
            
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
            //open url in webview
            await webViewController = WebViewController(redirectUrl: initParams.redirectUrl)
            await UIApplication.shared.keyWindow?.rootViewController?.present(webViewController, animated: true, completion: nil)
            await webViewController.webView.load(URLRequest(url: url))
        }
        else {
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
            let component = URLComponents.init(string: host + "?" + fragment),
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
    
    public func fetchProjectConfig() async throws  -> Bool {
        var response: Bool = false
        let api = Router.get([.init(name: "project_id", value: initParams.clientId), .init(name: "network", value: initParams.network.rawValue), .init(name: "whitelist", value: "true")])
        let result = await Service.request(router: api)
        switch result {
        case let .success(data):
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(ProjectConfigResponse.self, from: data)
                //os_log("fetchProjectConfig API response is: %@", log: getTorusLogger(log: Web3AuthLogger.network, type: .info), type: .info, "\(String(describing: result))")
                initParams.originData = result.whitelist.signedUrls.mergeMaps(other: initParams.originData)
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
        guard let state = state, let userInfo = state.userInfo else { throw Web3AuthError.noUserFound}
        return userInfo
    }
    
    public func getWeb3AuthResponse() throws -> Web3AuthState {
        guard let state = state else {
                throw Web3AuthError.noUserFound
            }
        return state
    }
    
    static func setSignResponse(_ response: SignResponse?) {
        signResponse = response
    }

    public static func getSignResponse() throws -> SignResponse? {
        if signResponse == nil {
            throw Web3AuthError.noUserFound
        }
        return signResponse
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
            let platformKeyRequest = platformProvider.createCredentialRegistrationRequest(challenge: optionsData.challenge.data(using: .utf8)!,
                                                                                          name: optionsData.user.name,  userID: optionsData.user.id.data(using: .utf8)!)
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
                  //showAlert(with: "Authorized with Passkeys", message: "Create account with credential ID = \(credential.credentialID)")
                
                // Take steps to handle the registration.
                //let passkeyVerifierId = getPasskeyVerifierId(credential.rawClientDataJSON)

                //let passkeyPublicKey = getPasskeyPublicKey(verifier: state?.userInfo?.verifier ?? "", verifierId: passkeyVerifierId)
                //let encryptedMetadata = getEncryptedMetadata(passkeyPubKey: passkeyPublicKey)
                
                //let verificationResult = verifyRegistration(registrationResponse: credential.rawClientDataJSON, signatures: (state?.signatures)!,
                                                            //passkeyToken: (state?.idToken)!, data: encryptedMetadata)
                
                } else if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
                  //showAlert(with: "Authorized with Passkeys", message: "Sign in with credential ID = \(credential.credentialID)")
                  let signature = credential.signature
                  let clientDataJSON = credential.rawClientDataJSON
                  
                  // Take steps to verify the challenge by sending it to your server tio verify
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
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor()
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
    
    /*func getEncryptedMetadata(passkeyPubKey: TorusPublicKey) throws -> String? {
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

        return encryptData(
            x: passkeyPubKey.finalKeyData?.X ?? "",
            y: passkeyPubKey.finalKeyData?.Y ?? "",
            data: jsonString
        )
    }
    
    private func encryptData(x: String, y: String, data: String) -> String {
        let publicKey: String = (x + y)
        let ecies = try await MetadataUtils.encrypt(publicKey: publicKey, msg: data)
        let data = JSONEncoder().encode(ecies)
        return String(data: data, encoding: .utf8)!
    }
    
    private func decryptData(data: String, privKey: String) -> String {
        let decrypted = try await MetadataUtils.decrypt(privateKey: privKey, opts: data)
        let data = JSONEncoder().encode(decrypted)
        return String(data: data, encoding: .utf8)!
    }*/
    
    private func verifyRegistration(
        registrationResponse: Foundation.Data,
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
    
    private func getAuthenticationOptions(authenticatorId: String, rpId: String) async throws -> AuthOptions {
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
                return result.data.options
            } catch {
                throw error
            }
        case let .failure(error):
            throw error
        }
    }
    
    private func verifyAuthentication(publicKeyCredential: Data) async throws -> VerifyAuthenticationResponse {
        Router.baseURL = PASSKEY_SVC_URL[initParams.buildEnv!] ?? ""
        let requestBody = VerifyAuthenticationRequest(
            web3authClientId: initParams.clientId,
            trackingId: self.trackingId!,
            verificationData: publicKeyCredential,
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
    
    private func getPasskeyPostboxKey(passKeyLoginParams: PassKeyLoginParams) async throws-> String {
        do {
            let nodeDetailManager = NodeDetailManager(network: WEB3AUTH_NETWORK_MAP[Network(rawValue: initParams.network.rawValue) ?? Network.sapphire_mainnet]!)
            let fnd = try await nodeDetailManager.getNodeDetails(verifier: passKeyLoginParams.verifier, verifierID: passKeyLoginParams.verifierId)
            
            let torusUtils = try! TorusUtils(params: TorusOptions(clientId: initParams.clientId, network: WEB3AUTH_NETWORK_MAP[Network(rawValue: initParams.network.rawValue) ?? Network.sapphire_mainnet]!, enableOneKey: true))
            let data = try await torusUtils.retrieveShares(endpoints: fnd.torusNodeEndpoints, verifier: passKeyLoginParams.verifier,
                                                           verifierParams: VerifierParams(verifier_id: passKeyLoginParams.verifierId), idToken: passKeyLoginParams.idToken)
            return data.finalKeyData.privKey
        } catch {
            print("Error fetching passkey private key: \(error)")
            throw error
        }
    }
    
}

extension Web3Auth: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
