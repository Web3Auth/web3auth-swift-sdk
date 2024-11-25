import AuthenticationServices
import curveSecp256k1
import OSLog
import SessionManager

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

    let SIGNER_MAP: [Network: String] = [
        .mainnet: "https://signer.web3auth.io",
        .testnet: "https://signer.web3auth.io",
        .cyan: "https://signer-polygon.web3auth.io",
        .aqua: "https://signer-polygon.web3auth.io",
        .sapphire_mainnet: "https://signer.web3auth.io",
        .sapphire_devnet: "https://signer.web3auth.io",
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
            
            DispatchQueue.main.async { // Ensure the UI-related setup is on the main thread.
                self.authSession = ASWebAuthenticationSession(
                    url: url, callbackURLScheme: redirectURL.scheme
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
                            
                            self.state = loginDetails
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
                
                DispatchQueue.main.async { // Ensure UI-related calls are made on the main thread
                    self.authSession = ASWebAuthenticationSession(
                        url: url, callbackURLScheme: redirectURL.scheme
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
                                self.state = loginDetails
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
            
            let url = try Web3Auth.generateAuthSessionURL(
                initParams: initParams,
                jsonObject: jsonObject,
                sdkUrl: initParams.walletSdkUrl?.absoluteString,
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
}

extension Web3Auth: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
