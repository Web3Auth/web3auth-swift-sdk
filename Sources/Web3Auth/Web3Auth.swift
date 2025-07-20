import AuthenticationServices
import curveSecp256k1
import OSLog
import SessionManager
import BigInt
#if canImport(UIKit)
import UIKit
#endif
import Combine
import FetchNodeDetails
import SessionManager
import TorusUtils
import JWTDecode
#if canImport(curveSecp256k1)
    import curveSecp256k1
#endif


/**
 Authentication using Web3Auth.
 */

public class Web3Auth: NSObject {
    private var web3AuthOptions: Web3AuthOptions
    private var authSession: ASWebAuthenticationSession?
    // You can check the web3AuthResponse variable before logging the user in, if the user
    // has an active session the web3AuthResponse variable will already have all the values you
    // get from login so the user does not have to re-login
    public var web3AuthResponse: Web3AuthResponse?
    var sessionManager: SessionManager
    var webViewController: WebViewController = DispatchQueue.main.sync { WebViewController(onSignResponse: { _ in }) }
    private var loginParams: LoginParams?
    private static var signResponse: SignResponse?
    private var projectConfigResponse: ProjectConfigResponse? = nil
    let nodeDetailManager: NodeDetailManager
    let torusUtils: TorusUtils

    let SIGNER_MAP: [Web3AuthNetwork: String] = [
        .MAINNET: "https://signer.web3auth.io",
        .TESTNET: "https://signer.web3auth.io",
        .CYAN: "https://signer-polygon.web3auth.io",
        .AQUA: "https://signer-polygon.web3auth.io",
        .SAPPHIRE_MAINNET: "https://signer.web3auth.io",
        .SAPPHIRE_DEVNET: "https://signer.web3auth.io",
    ]
    /**
     Web3Auth  component for authenticating with web-based flow.

     ```
     Web3Auth(Web3AuthOptions(clientId: clientId, network: .mainnet))
     ```

     - parameter params: Init params for your Web3Auth instance.

     - returns: Web3Auth component.
     */
    public init(options: Web3AuthOptions) async throws {
        web3AuthOptions = options
        Router.baseURL = SIGNER_MAP[options.web3AuthNetwork] ?? ""
        let isSFA = KeychainHelper.shared.get(forKey: "isSFA", as: Bool.self)
        let sessionNamespace = isSFA ?? false ? "sfa" : ""
        sessionManager = SessionManager(sessionTime: options.sessionTime, allowedOrigin: options.redirectUrl, sessionNamespace: sessionNamespace)
        nodeDetailManager = NodeDetailManager(network: options.web3AuthNetwork)
        let torusOptions = TorusOptions(clientId: options.clientId, network: options.web3AuthNetwork, serverTimeOffset: options.sessionTime, enableOneKey: true)
        try torusUtils = TorusUtils(params: torusOptions)
        super.init()
        let fetchConfigResult = try await fetchProjectConfig()
        if fetchConfigResult {
            let sessionId = SessionManager.getSessionIdFromStorage()
            if sessionId != nil {
                sessionManager.setSessionId(sessionId: sessionId!)
                do {
                    // Restore from valid session
                    let loginDetailsDict = try await sessionManager.authorizeSession(origin: options.redirectUrl)
                    guard let loginDetails = Web3AuthResponse(dict: loginDetailsDict, sessionID: sessionManager.getSessionId(), web3AuthNetwork: options.web3AuthNetwork)
                    else {
                        throw Web3AuthError.decodingError
                    }
                    web3AuthResponse = loginDetails
                } catch SessionManagerError.dataNotFound {
                    // Clear invalid session
                    SessionManager.deleteSessionIdFromStorage()
                    sessionManager.setSessionId(sessionId: "")
                }
            }
        }
    }

    public func logout() async throws {
        guard let web3AuthResponse = web3AuthResponse else { throw Web3AuthError.noUserFound }
        try await sessionManager.invalidateSession()
        SessionManager.deleteSessionIdFromStorage()
        if let authConnectionId = web3AuthResponse.userInfo?.authConnectionId, let dappShare = KeychainManager.shared.getDappShare(authConnectionId: authConnectionId) {
            KeychainManager.shared.delete(key: .custom(dappShare))
        }
        KeychainHelper.shared.clearAll()
        self.web3AuthResponse = nil
    }

    public func getLoginId<T: Encodable>(sessionId: String, data: T) async throws -> String? {
        sessionManager.setSessionId(sessionId: sessionId)
        return try await sessionManager.createSession(data: data)
    }

    private func getLoginDetails(_ callbackURL: URL) async throws -> Web3AuthResponse {
        let loginDetailsDict = try await sessionManager.authorizeSession(origin: web3AuthOptions.redirectUrl)
        guard
            let loginDetails = Web3AuthResponse(dict: loginDetailsDict, sessionID: sessionManager.getSessionId(), web3AuthNetwork: web3AuthOptions.web3AuthNetwork)
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
        try await self.init(options: Web3AuthOptions(
            clientId: values.clientId,
            web3AuthNetwork: values.web3AuthNetwork,
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
                             Type of login: \(result.userInfo.authConnection)
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
    public func login(loginParams: LoginParams) async throws -> Web3AuthResponse {
        self.loginParams = loginParams
        // assign loginParams redirectUrl from intiParamas redirectUrl
        
        if let authConnectionConfig = web3AuthOptions.authConnectionConfig?.first,
           let savedDappShare = KeychainManager.shared.getDappShare(authConnectionId: authConnectionConfig.authConnectionId) {
            self.loginParams?.dappShare = savedDappShare
        }
    
        let sdkUrlParams = SdkUrlParams(options: web3AuthOptions, params: self.loginParams!, actionType: "login")
        let sessionId = try SessionManager.generateRandomSessionID()!
        let loginId = try await getLoginId(sessionId: sessionId, data: sdkUrlParams)

        let jsonObject: [String: String?] = [
            "loginId": loginId,
        ]

        let url = try Web3Auth.generateAuthSessionURL(web3AuthOptions: web3AuthOptions, jsonObject: jsonObject, sdkUrl: web3AuthOptions.sdkUrl, path: "start")

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Web3AuthResponse, Error>) in

            DispatchQueue.main.async { [self] in // Ensure the UI-related setup is on the main thread.
                self.authSession = ASWebAuthenticationSession(
                    url: url, callbackURLScheme: URL(string: self.web3AuthOptions.redirectUrl)?.scheme
                ) { callbackURL, authError in

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

                            self.web3AuthResponse = loginDetails
                            continuation.resume(returning: loginDetails)
                        } catch {
                            continuation.resume(throwing: Web3AuthError.unknownError)
                        }
                    }
                }

                self.authSession?.presentationContextProvider = self

                if !(self.authSession?.start() ?? false) {
                    continuation.resume(throwing: Web3AuthError.unknownError)
                }
            }
        })
    }
    
    public func connectTo(loginParams: LoginParams) async throws -> Web3AuthResponse {
        
        sessionManager = SessionManager(
            sessionTime: self.web3AuthOptions.sessionTime,
            allowedOrigin: web3AuthOptions.redirectUrl,
            sessionNamespace: (loginParams.idToken?.isEmpty == false) ? "sfa" : ""
        )
        // Case 1: No idToken provided
        if loginParams.idToken?.isEmpty ?? true {
            if let loginHint = loginParams.loginHint, !loginHint.isEmpty {
                // Create or update extraLoginOptions with loginHint
                var updatedExtraLoginOptions = loginParams.extraLoginOptions
                if updatedExtraLoginOptions == nil {
                    updatedExtraLoginOptions = ExtraLoginOptions(login_hint: loginHint)
                } else {
                    updatedExtraLoginOptions?.login_hint = loginHint
                }
                
                var updatedLoginParams = loginParams
                updatedLoginParams.extraLoginOptions = updatedExtraLoginOptions
                
                return try await login(loginParams: updatedLoginParams) // PnP login
            } else {
                return try await login(loginParams: loginParams) // PnP login
            }
        }
        
        // Case 2: idToken exists
        if let groupedId = loginParams.groupedAuthConnectionId, !groupedId.isEmpty {
            let newLoginParams = LoginParams(
                authConnection: .CUSTOM,
                authConnectionId: groupedId,
                idToken: loginParams.idToken
            )
            let subVerifierInfoArray = [
                Web3AuthSubVerifierInfo(
                    verifier: loginParams.authConnectionId ?? "",
                    idToken: loginParams.idToken ?? ""
                )
            ]
            KeychainHelper.shared.save(true, forKey: KeychainKeys.isSFA)
            return try await connect(loginParams: newLoginParams, subVerifierInfoArray: subVerifierInfoArray)
        } else {
            KeychainHelper.shared.save(true, forKey: KeychainKeys.isSFA)
            return try await connect(loginParams: loginParams) // SFA login fallback
        }
    }

    
    private func getTorusKey(loginParams: LoginParams, subVerifierInfoArray: [Web3AuthSubVerifierInfo]? = nil) async throws -> TorusKey {
        var retrieveSharesResponse: TorusKey

        let userId = getUserId(from: loginParams.idToken!)
        let details = try await nodeDetailManager.getNodeDetails(verifier: loginParams.authConnectionId!, verifierID: userId!)
        
        if let subVerifierInfoArray = subVerifierInfoArray, !subVerifierInfoArray.isEmpty {
            var aggregateIdTokenSeeds = [String]()
            var subVerifierIds = [String]()
            var verifyParams = [VerifyParams]()
            for value in subVerifierInfoArray {
                aggregateIdTokenSeeds.append(value.idToken)

                let verifyParam = VerifyParams(verifier_id: userId, idtoken: value.idToken)

                verifyParams.append(verifyParam)
                subVerifierIds.append(value.verifier)
            }
            aggregateIdTokenSeeds.sort()

            let verifierParams = VerifierParams(verifier_id: userId!, sub_verifier_ids: subVerifierIds, verify_params: verifyParams)

            let aggregateIdToken = try curveSecp256k1.keccak256(data: Data(aggregateIdTokenSeeds.joined(separator: "\u{001d}").utf8)).toHexString()
            
            retrieveSharesResponse = try await torusUtils.retrieveShares(
                endpoints: details.getTorusNodeEndpoints(),
                verifier: loginParams.authConnectionId!,
                verifierParams: verifierParams,
                idToken: aggregateIdToken
            )
        } else {
            let verifierParams = VerifierParams(verifier_id: userId!)

            retrieveSharesResponse = try await torusUtils.retrieveShares(
                endpoints: details.getTorusNodeEndpoints(),
                verifier: loginParams.authConnectionId!,
                verifierParams: verifierParams,
                idToken: loginParams.idToken!
            )
        }
        
        if retrieveSharesResponse.metadata.upgraded == true {
            throw Web3AuthError.mfaAlreadyEnabled
        }

        return retrieveSharesResponse
    }

    public func connect(loginParams: LoginParams,  subVerifierInfoArray: [Web3AuthSubVerifierInfo]? = nil) async throws -> Web3AuthResponse {
        let torusKey: TorusKey
        if let array = subVerifierInfoArray, !array.isEmpty {
            torusKey = try await getTorusKey(loginParams: loginParams, subVerifierInfoArray: array)
        } else {
            torusKey = try await getTorusKey(loginParams: loginParams)
        }

        let privateKey = if (torusKey.finalKeyData.privKey.isEmpty) {
            torusKey.oAuthKeyData.privKey
        } else {
            torusKey.finalKeyData.privKey
        }

        var decodedUserInfo: Web3AuthUserInfo? = nil
        
        do {
            let jwt = try decode(jwt: loginParams.idToken!)
            decodedUserInfo = Web3AuthUserInfo.init(email: jwt.body["email"] as? String ?? "",
                                                    name: jwt.body["name"] as? String ?? "",
                                                    profileImage: jwt.body["picture"] as? String ?? "",
                                                    groupedAuthConnectionId: nil,
                                                    authConnectionId: loginParams.authConnectionId, userId: jwt.body["user_id"] as? String ?? "",
                                                    dappShare: nil, idToken: nil, oAuthIdToken: nil, oAuthAccessToken: nil, isMfaEnabled: false, authConnection: "custom", appState: nil)
        } catch {
            throw Web3AuthError.inValidLogin
        }
        
        let sessionId = try SessionManager.generateRandomSessionID()!
        sessionManager.setSessionId(sessionId: sessionId)
        
        let web3AuthResponse = Web3AuthResponse(privateKey: privateKey, ed25519PrivateKey: nil, sessionId: nil, userInfo: decodedUserInfo, error: nil, coreKitKey: nil, coreKitEd25519PrivKey: nil, factorKey: nil, signatures: getSignatureData(sessionTokenData: torusKey.sessionData.sessionTokenData), tssShareIndex: 0, tssPubKey: nil, tssShare: nil, tssTag: nil, tssNonce: 0, nodeIndexes: [], keyMode: nil)
    
        _ = try await sessionManager.createSession(data: web3AuthResponse)
        
        SessionManager.saveSessionIdToStorage(sessionId)
        sessionManager.setSessionId(sessionId: sessionId)
        //self.state = sfaKey
        return web3AuthResponse
    }
    
    private func getSignatureData(sessionTokenData: [SessionToken?]) -> [String] {
        return sessionTokenData
            .compactMap { $0 } // Filters out nil values
            .map { session in
                """
                {"data":"\(session.token)","sig":"\(session.signature)"}
                """
            }
    }
    
    private func getUserId(from token: String) -> String? {
        do {
            let jwt = try decode(jwt: token)
            return jwt.claim(name: "user_id").string
        } catch {
            print("Failed to decode JWT: \(error)")
            return nil
        }
    }

    public func enableMFA(_ loginParams: LoginParams? = nil) async throws -> Bool {
        // Note that this function can be called without login on restored session, so loginParams should not be optional.
        if web3AuthResponse?.userInfo?.isMfaEnabled == true {
            throw Web3AuthError.mfaAlreadyEnabled
        }
        
        if let idToken = self.loginParams?.idToken, !idToken.isEmpty {
            throw Web3AuthError.enabledMfaNotAllowed
        }
        
        let sessionId = SessionManager.getSessionIdFromStorage()!
        if !sessionId.isEmpty {
            if loginParams != nil {
                self.loginParams = loginParams
            }
            var extraLoginOptions: ExtraLoginOptions? = ExtraLoginOptions()
            if loginParams?.extraLoginOptions != nil {
                extraLoginOptions = loginParams?.extraLoginOptions
            } else {
                extraLoginOptions = self.loginParams?.extraLoginOptions
            }
            extraLoginOptions?.login_hint = web3AuthResponse?.userInfo?.userId

            let jsonData = try? JSONEncoder().encode(extraLoginOptions)
            let _extraLoginOptions = String(data: jsonData!, encoding: .utf8)
            
            let redirectUrl = web3AuthOptions.redirectUrl
            
            let newSessionId = try SessionManager.generateRandomSessionID()!
            let loginIdObject: [String: String?] = [
                "loginId": newSessionId,
                "platform": "iOS",
            ]
            
            let jsonEncoder = JSONEncoder()
            let data = try? jsonEncoder.encode(loginIdObject)
            
            let params: [String: String?] = [
                "authConnection": web3AuthResponse?.userInfo?.authConnection,
                "authConnectionId": web3AuthResponse?.userInfo?.authConnectionId,
                "mfaLevel": MFALevel.MANDATORY.rawValue,
                "redirectUrl": redirectUrl,
                "extraLoginOptions": _extraLoginOptions,
                "appState": data?.toBase64URL(),
            ]

            let setUpMFAParams = SetUpMFAParams(options: web3AuthOptions, params: params, actionType: "enable_mfa", sessionId: sessionId)
            if let jsonData = try? JSONEncoder().encode(setUpMFAParams),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("setUpMFAParams JSON: \(jsonString)")
            }
            
            let loginId = try await getLoginId(sessionId: newSessionId, data: setUpMFAParams)

            let jsonObject: [String: String?] = [
                "loginId": loginId,
            ]

            let url = try Web3Auth.generateAuthSessionURL(web3AuthOptions: web3AuthOptions, jsonObject: jsonObject, sdkUrl: web3AuthOptions.sdkUrl, path: "start")

            return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Bool, Error>) in

                DispatchQueue.main.async { // Ensure UI-related calls are made on the main thread
                    self.authSession = ASWebAuthenticationSession(
                        url: url, callbackURLScheme: URL(string: self.web3AuthOptions.redirectUrl)?.scheme
                    ) { callbackURL, authError in
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
                                self.web3AuthResponse = loginDetails
                                continuation.resume(returning: true)
                            } catch {
                                continuation.resume(throwing: Web3AuthError.unknownError)
                            }
                        }
                    }
                    self.authSession?.presentationContextProvider = self

                    if !(self.authSession?.start() ?? false) {
                        continuation.resume(throwing: Web3AuthError.unknownError)
                    }
                }
            })
        } else {
            throw Web3AuthError.runtimeError("SessionId not found. Please login first.")
        }
    }
    
    public func manageMFA(_ loginParams: LoginParams? = nil) async throws -> Bool {
        if web3AuthResponse?.userInfo?.isMfaEnabled == false {
            throw Web3AuthError.mfaNotEnabled
        }
        
        if let idToken = self.loginParams?.idToken, !idToken.isEmpty {
            throw Web3AuthError.enabledMfaNotAllowed
        }
        
        let sessionId = SessionManager.getSessionIdFromStorage()!
        if sessionId.isEmpty {
            throw Web3AuthError.runtimeError("SessionId not found. Please login first.")
        }

        var modifiedLoginParams = self.loginParams
        var modifiedInitParams = web3AuthOptions

        if loginParams != nil {
            modifiedLoginParams = loginParams
            //modifiedLoginParams?.redirectUrl = modifiedInitParams.dashboardUrl
        }

        var extraLoginOptions: ExtraLoginOptions? = modifiedLoginParams?.extraLoginOptions ?? loginParams?.extraLoginOptions ?? ExtraLoginOptions()
        extraLoginOptions?.login_hint = web3AuthResponse?.userInfo?.userId

        let jsonData = try? JSONEncoder().encode(extraLoginOptions)
        let _extraLoginOptions = jsonData.flatMap { String(data: $0, encoding: .utf8) }
        
        let newSessionId = try SessionManager.generateRandomSessionID()!
        let loginIdObject: [String: String?] = [
            "loginId": newSessionId,
            "platform": "iOS",
        ]
        
        let jsonEncoder = JSONEncoder()
        let data = try? jsonEncoder.encode(loginIdObject)
        
        let dappUrl = self.web3AuthOptions.redirectUrl
        
        let params: [String: String?] = [
            "authConnection": web3AuthResponse?.userInfo?.authConnection,
            "authConnectionId": web3AuthResponse?.userInfo?.authConnectionId,
            "mfaLevel": MFALevel.MANDATORY.rawValue,
            "redirectUrl": modifiedInitParams.dashboardUrl,
            "extraLoginOptions": _extraLoginOptions,
            "appState": data?.toBase64URL(),
            "dappUrl": dappUrl
        ]
        
        modifiedInitParams.redirectUrl = modifiedInitParams.dashboardUrl!

        let setUpMFAParams = SetUpMFAParams(options: modifiedInitParams, params: params, actionType: "manage_mfa", sessionId: sessionId)
        let loginId = try await getLoginId(sessionId: newSessionId, data: setUpMFAParams)

        let jsonObject: [String: String?] = ["loginId": loginId]

        let url = try Web3Auth.generateAuthSessionURL(web3AuthOptions: modifiedInitParams, jsonObject: jsonObject, sdkUrl: modifiedInitParams.sdkUrl, path: "start")

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            DispatchQueue.main.async {
                self.authSession = ASWebAuthenticationSession(
                    url: url, callbackURLScheme: URL(string: dappUrl)?.scheme
                ) { _, authError in
                    if let authError = authError {
                        if case ASWebAuthenticationSessionError.canceledLogin = authError {
                            continuation.resume(throwing: Web3AuthError.userCancelled)
                        } else {
                            continuation.resume(throwing: authError)
                        }
                        return
                    }

                    continuation.resume(returning: true)
                }

                self.authSession?.presentationContextProvider = self

                if !(self.authSession?.start() ?? false) {
                    continuation.resume(throwing: Web3AuthError.unknownError)
                }
            }
        }
    }
    
    public func showWalletUI(path: String? = "wallet") async throws {
        let savedSessionId = SessionManager.getSessionIdFromStorage()!
        if !savedSessionId.isEmpty {
            var initOptionsJson = try JSONSerialization.jsonObject(with: JSONEncoder().encode(web3AuthOptions)) as! [String: Any]

            if let chains = projectConfigResponse?.chains {
                let chainsData = try JSONEncoder().encode(chains)
                let chainsJson = try JSONSerialization.jsonObject(with: chainsData) as! [Any]
                initOptionsJson["chains"] = chainsJson
                initOptionsJson["chainId"] = chains.first?.chainId ?? web3AuthOptions.defaultChainId ?? "0x1"
            }


            if let embeddedWalletAuth = projectConfigResponse?.embeddedWalletAuth {
                let authData = try JSONEncoder().encode(embeddedWalletAuth)
                let authArray = try JSONSerialization.jsonObject(with: authData) as! [Any]
                initOptionsJson["embeddedWalletAuth"] = authArray
            }

            if let smartAccounts = projectConfigResponse?.smartAccounts {
                let saData = try JSONEncoder().encode(smartAccounts)
                let saJson = try JSONSerialization.jsonObject(with: saData) as! [String: Any]
                initOptionsJson["accountAbstractionConfig"] = saJson
            }

            let paramMap: [String: Any] = [
                "options": initOptionsJson
            ]

            let sessionId = try SessionManager.generateRandomSessionID()!
            let jsonData = try JSONSerialization.data(withJSONObject: paramMap)
            let jsonString = String(data: jsonData, encoding: .utf8)!

            let loginId = try await getLoginId(sessionId: sessionId, data: jsonString)

            var jsonObject: [String: String?] = [
                "loginId": loginId,
                "sessionId": savedSessionId,
                "platform": "ios",
            ]
            
            if let isSFA = KeychainHelper.shared.get(forKey: "isSFA", as: Bool.self), isSFA {
                jsonObject["sessionNamespace"] = "sfa"
            }

            let url = try Web3Auth.generateAuthSessionURL(
                web3AuthOptions: web3AuthOptions,
                jsonObject: jsonObject,
                sdkUrl: web3AuthOptions.walletSdkUrl,
                path: path
            )

            // Ensure UI-related operations occur on the main thread
            await MainActor.run {
                guard let rootViewController = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.rootViewController else {
                    return
                }
                rootViewController.present(webViewController, animated: true) {
                    self.webViewController.webView.load(URLRequest(url: url))
                }
            }
        } else {
            throw Web3AuthError.runtimeError("SessionId not found. Please login first.")
        }
    }

    public func request(method: String, requestParams: [Any], path: String? = "wallet/request", appState: String? = nil) async throws -> SignResponse? {
        let sessionId = SessionManager.getSessionIdFromStorage()!
        if !sessionId.isEmpty {
            var initOptionsJson = try JSONSerialization.jsonObject(with: JSONEncoder().encode(web3AuthOptions)) as! [String: Any]

            if let chains = projectConfigResponse?.chains {
                let chainsData = try JSONEncoder().encode(chains)
                let chainsJson = try JSONSerialization.jsonObject(with: chainsData) as! [Any]
                initOptionsJson["chains"] = chainsJson
                initOptionsJson["chainId"] = chains.first?.chainId ?? web3AuthOptions.defaultChainId ?? "0x1"
            }

            if let embeddedWalletAuth = projectConfigResponse?.embeddedWalletAuth {
                let authData = try JSONEncoder().encode(embeddedWalletAuth)
                let authArray = try JSONSerialization.jsonObject(with: authData) as! [Any]
                initOptionsJson["embeddedWalletAuth"] = authArray
            }

            if let smartAccounts = projectConfigResponse?.smartAccounts {
                let saData = try JSONEncoder().encode(smartAccounts)
                let saJson = try JSONSerialization.jsonObject(with: saData) as! [String: Any]
                initOptionsJson["accountAbstractionConfig"] = saJson
            }

            let paramMap: [String: Any] = [
                "options": initOptionsJson
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: paramMap)
            let jsonString = String(data: jsonData, encoding: .utf8)!

            let loginId = try SessionManager.generateRandomSessionID()!
            let _loginId = try await getLoginId(sessionId: loginId, data: jsonString)

            var signMessageMap: [String: String] = [:]
            signMessageMap["loginId"] = _loginId
            signMessageMap["sessionId"] = sessionId
            signMessageMap["platform"] = "ios"
            signMessageMap["appState"] = appState
            
            if let isSFA = KeychainHelper.shared.get(forKey: "isSFA", as: Bool.self), isSFA {
                signMessageMap["sessionNamespace"] = "sfa"
            }

            var requestData: [String: Any] = [:]
            requestData["method"] = method
            requestData["params"] = try? JSONSerialization.jsonObject(with: JSONSerialization.data(withJSONObject: requestParams), options: []) as? [Any]

            if let requestDataJson = try? JSONSerialization.data(withJSONObject: requestData, options: []),
               let requestDataJsonString = String(data: requestDataJson, encoding: .utf8) {
                // Add the requestData JSON string to signMessageMap as a property
                signMessageMap["request"] = requestDataJsonString
            }

            let url = try Web3Auth.generateAuthSessionURL(web3AuthOptions: web3AuthOptions, jsonObject: signMessageMap, sdkUrl: web3AuthOptions.walletSdkUrl,
                                                          path: path)

            // open url in webview
            return await withCheckedContinuation { continuation in
                Task {
                    let webViewController = await MainActor.run {
                        WebViewController(redirectUrl: web3AuthOptions.redirectUrl, onSignResponse: { signResponse in
                            continuation.resume(returning: signResponse)
                        }, onCancel: {
                            continuation.resume(returning: nil)
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

    static func generateAuthSessionURL(web3AuthOptions: Web3AuthOptions, jsonObject: [String: String?], sdkUrl: String?, path: String?) throws -> URL {
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
        guard
            let host = callbackURL.host,
            let fragment = callbackURL.fragment,
            let component = URLComponents(string: host + "?" + fragment),
            let queryItems = component.queryItems,
            let b64ParamsItem = queryItems.first(where: { $0.name == "b64Params" }),
            let callbackFragment = b64ParamsItem.value,
            let callbackData = Data.fromBase64URL(callbackFragment)
        else {
            throw Web3AuthError.decodingError
        }

        // Decode JSON into SessionResponse
        guard let callbackState = try? JSONDecoder().decode(SessionResponse.self, from: callbackData) else {
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
        let api = Router.get([.init(name: "project_id", value: web3AuthOptions.clientId), .init(name: "network", value: web3AuthOptions.web3AuthNetwork.name), .init(name: "build_env", value: web3AuthOptions.authBuildEnv?.rawValue)])
        let result = await Service.request(router: api)
        switch result {
        case let .success(data):
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(ProjectConfigResponse.self, from: data)
                // os_log("fetchProjectConfig API response is: %@", log: getTorusLogger(log: Web3AuthLogger.network, type: .info), type: .info, "\(String(describing: result))")
                projectConfigResponse = result
                web3AuthOptions.originData = result.whitelist.signedUrls.merging(web3AuthOptions.originData ?? [:]) { _, new in new }
                web3AuthOptions.authConnectionConfig =
                    (web3AuthOptions.authConnectionConfig ?? []) + (projectConfigResponse?.embeddedWalletAuth ?? [])
                if let whiteLabelData = result.whitelabel {
                    web3AuthOptions.whiteLabel = web3AuthOptions.whiteLabel?.merge(with: whiteLabelData) ?? whiteLabelData
                    if web3AuthOptions.walletServicesConfig == nil {
                        web3AuthOptions.walletServicesConfig = WalletServicesConfig()
                    }
                    if var walletConfig = web3AuthOptions.walletServicesConfig {
                        walletConfig.whiteLabel = walletConfig.whiteLabel?.merge(with: whiteLabelData) ?? whiteLabelData
                        web3AuthOptions.walletServicesConfig = walletConfig
                    }
                }
                response = true
            } catch {
                //print("Decoding failed: \(error)")
                throw error
            }
        case let .failure(error):
            throw error
        }
        return response
    }

    public func getPrivateKey() -> String {
        if web3AuthResponse == nil {
            return ""
        }
        let privateKey: String = web3AuthOptions.useSFAKey == true ? web3AuthResponse?.coreKitKey ?? "" : web3AuthResponse?.privateKey ?? ""
        return privateKey
    }

    public func getEd25519PrivateKey() -> String {
        if web3AuthResponse == nil {
            return ""
        }
        let ed25519Key: String = web3AuthOptions.useSFAKey == true ?
        web3AuthResponse?.coreKitEd25519PrivKey ?? "" : web3AuthResponse?.ed25519PrivateKey ?? ""
        return ed25519Key
    }

    public func getUserInfo() throws -> Web3AuthUserInfo {
        guard let web3AuthResponse = web3AuthResponse, let userInfo = web3AuthResponse.userInfo else { throw Web3AuthError.noUserFound }
        return userInfo
    }

    public func getWeb3AuthResponse() throws -> Web3AuthResponse {
        guard let web3AuthResponse = web3AuthResponse else {
            throw Web3AuthError.noUserFound
        }
        return web3AuthResponse
    }
}

extension Web3Auth: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
