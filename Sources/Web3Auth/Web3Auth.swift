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
import TorusUtils
import JWTDecode

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
    /// Session-service storage for ephemeral login payloads (`/start` loginId) and SFA sessions.
    var storageManager: StorageManager<Web3AuthResponse>
    /// Citadel token session manager.
    var authSessionManager: AuthSessionManager<Web3AuthResponse>
    var webViewController: WebViewController = DispatchQueue.main.sync { WebViewController(onSignResponse: { _ in }) }
    private var loginParams: LoginParams?
    private static var signResponse: SignResponse?
    private var projectConfigResponse: ProjectConfigResponse? = nil
    let nodeDetailManager: NodeDetailManager
    let torusUtils: TorusUtils
    private let startTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000)

    private struct WalletLaunchCreds {
        let sessionId: String
        let accessToken: String?
        let idToken: String?
        let refreshToken: String?
    }

    /**
     Web3Auth  component for authenticating with web-based flow.

     ```
     Web3Auth(Web3AuthOptions(clientId: clientId, network: .mainnet))
     ```

     - parameter params: Init params for your Web3Auth instance.

     - returns: Web3Auth component.
     */
    public init(options: Web3AuthOptions) async throws {
        
        // Segment analytics Initilization
        AnalyticsManager.shared.initialize()
        
        AnalyticsManager.shared.identify(
            userId: options.clientId,
            traits: [
                "web3auth_client_id": options.clientId,
                "web3auth_network": options.web3AuthNetwork
            ]
        )
        
        AnalyticsManager.shared.setGlobalProperties([
            "sdk_name": options.getSdkName(),
            "sdk_version": options.getSdkVersion(),
            "web3auth_client_id": options.clientId,
            "web3auth_network": options.web3AuthNetwork,
            "integration_type": AnalyticsIntegrationType.nativeSDK
        ])
        
        web3AuthOptions = options
        Router.baseURL = Web3AuthUrls.dashboardPublicApiUrl(options.authBuildEnv)
        storageManager = try Web3Auth.makeStorageManager(options: options, sessionNamespace: Web3Auth.resolveSessionNamespace(from: options))
        authSessionManager = Web3Auth.makeAuthSessionManager(options: options)
        let fndBuildEnv = Web3Auth.toFndBuildEnv(options.authBuildEnv)
        nodeDetailManager = NodeDetailManager(network: options.web3AuthNetwork, buildEnv: fndBuildEnv)
        let torusOptions = TorusOptions(
            clientId: options.clientId,
            network: options.web3AuthNetwork,
            buildEnv: fndBuildEnv,
            serverTimeOffset: options.sessionTime ?? 0,
            enableOneKey: true,
            source: options.isFlutterAnalytics ? LOGIN_SOURCE_FLUTTER : LOGIN_SOURCE_IOS
        )
        try torusUtils = TorusUtils(params: torusOptions)
        super.init()
        let fetchConfigResult = try await fetchProjectConfig()
        if fetchConfigResult {
            do {
                web3AuthResponse = try await authorizeSession()
            } catch {
                try? await authSessionManager.clearSessionData()
                StorageManager<Web3AuthResponse>.deleteSessionIdFromStorage()
            }
        }
    }

    public func logout() async throws {
        AnalyticsManager.shared.trackEvent(
            AnalyticsEvents.logoutStarted
        )
        let storedSessionId = StorageManager<Web3AuthResponse>.getSessionIdFromStorage() ?? ""
        if !storedSessionId.isEmpty {
            try? storageManager.setSessionId(sessionId: storedSessionId)
            _ = try? await storageManager.invalidateSession()
        }
        let accessToken = try? await authSessionManager.getAccessToken()
        if let accessToken, !accessToken.isEmpty {
            try? await authSessionManager.logout()
        } else {
            try? await authSessionManager.clearSessionData()
        }
        StorageManager<Web3AuthResponse>.deleteSessionIdFromStorage()
        if let authConnectionId = web3AuthResponse?.userInfo?.authConnectionId, let dappShare = KeychainManager.shared.getDappShare(authConnectionId: authConnectionId) {
            KeychainManager.shared.delete(key: .custom(dappShare))
        }
        KeychainHelper.shared.clearAll()
        self.web3AuthResponse = nil
        AnalyticsManager.shared.trackEvent(
            AnalyticsEvents.logoutCompleted
        )
    }

    public func getLoginId<T: Codable>(sessionId: String, data: T) async throws -> String? {
        let manager: StorageManager<T> = try createStorageManager(sessionNamespace: resolveSessionNamespace(), sessionId: sessionId)
        return try await manager.createSession(data: data)
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
    @MainActor
    public func login(loginParams: LoginParams) async throws -> Web3AuthResponse {
        self.loginParams = loginParams
        
        // Restore saved dapp share if available
        if let authConnectionConfig = web3AuthOptions.authConnectionConfig?.first,
           let savedDappShare = KeychainManager.shared.getDappShare(authConnectionId: authConnectionConfig.authConnectionId) {
            self.loginParams?.dappShare = savedDappShare
        }

        storageManager = try createStorageManager(sessionNamespace: resolveSessionNamespace())
        authSessionManager = createAuthSessionManager()

        let sdkUrlParams = SdkUrlParams(options: web3AuthOptions, params: self.loginParams!, actionType: "login")
        let sessionId = try StorageManager<Web3AuthResponse>.generateRandomSessionKey()
        let recordId = loginParams.recordId?.isEmpty == false ? loginParams.recordId! : generateRecordId()
        let loginSource = resolveLoginSource(loginParams)
        let loginId = try await getLoginId(sessionId: sessionId, data: sdkUrlParams)

        let jsonObject = makeStartConfigParams(loginId: loginId, recordId: recordId, loginSource: loginSource)

        let url = try Web3Auth.generateAuthSessionURL(
            web3AuthOptions: web3AuthOptions,
            jsonObject: jsonObject,
            sdkUrl: web3AuthOptions.sdkUrl,
            path: "start"
        )

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Web3AuthResponse, Error>) in
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: Web3AuthError.unknownError)
                    return
                }

                self.authSession = ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: URL(string: self.web3AuthOptions.redirectUrl)?.scheme
                ) { [weak self] callbackURL, authError in
                    guard let self else {
                        continuation.resume(throwing: Web3AuthError.unknownError)
                        return
                    }

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

                    Task { [weak self] in
                        guard let self else {
                            continuation.resume(throwing: Web3AuthError.unknownError)
                            return
                        }

                        do {
                            try await self.persistAuthTokens(sessionResponse)
                            let loginDetails = try await self.authorizeSession()
                            if let safeUserInfo = loginDetails.userInfo {
                                KeychainManager.shared.saveDappShare(userInfo: safeUserInfo)
                            }

                            self.web3AuthResponse = loginDetails
                            var analyticsProps: [String: Any] = [
                                "connector": "auth",
                                "auth_connection": loginParams.authConnection,
                                "auth_connection_id": loginParams.authConnectionId?.description ?? "",
                                "group_auth_connection_id": loginParams.groupedAuthConnectionId?.description ?? "",
                                "chain_id": self.web3AuthOptions.defaultChainId?.description ?? "",
                                "dapp_url": loginParams.dappUrl ?? "",
                                "chains": self.web3AuthOptions.chains?.description ?? "[]",
                                "integration_type": self.web3AuthOptions.getSdkName(),
                                "is_sfa": false
                            ]

                            analyticsProps["duration"] = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime)

                            AnalyticsManager.shared.trackEvent(
                                AnalyticsEvents.connectionCompleted,
                                properties: analyticsProps
                            )

                            continuation.resume(returning: loginDetails)
                        } catch {
                            let duration = Date().timeIntervalSince1970 * 1000 - Double(self.startTime)

                            let properties: [String: Any] = [
                                "connector": "auth",
                                "auth_connection": loginParams.authConnection,
                                "auth_connection_id": loginParams.authConnectionId?.description ?? "",
                                "group_auth_connection_id": loginParams.groupedAuthConnectionId?.description ?? "",
                                "chain_id": self.web3AuthOptions.defaultChainId?.description ?? "",
                                "dapp_url": loginParams.dappUrl ?? "",
                                "chains": self.web3AuthOptions.chains?.description ?? "[]",
                                "auth_ux_mode": "popup",
                                "is_sfa": false,
                                "duration": duration,
                                "error_message": "\(error)"
                            ]

                            AnalyticsManager.shared.trackEvent(AnalyticsEvents.connectionFailed, properties: properties)
                            continuation.resume(throwing: error)
                        }
                    }
                }

                self.authSession?.presentationContextProvider = self

                if !(self.authSession?.start() ?? false) {
                    continuation.resume(throwing: Web3AuthError.unknownError)
                }
            }
        }
    }

    
    public func connectTo(loginParams: LoginParams) async throws -> Web3AuthResponse {
        storageManager = try createStorageManager(
            sessionNamespace: (loginParams.idToken?.isEmpty == false) ? "sfa" : resolveSessionNamespace()
        )
        authSessionManager = createAuthSessionManager()
        
        var analyticsProps: [String: Any] = [
            "connector": "auth",
            "auth_connection": loginParams.authConnection,
            "auth_connection_id": loginParams.authConnectionId?.description ?? "",
            "group_auth_connection_id": loginParams.groupedAuthConnectionId?.description ?? "",
            "chain_id": web3AuthOptions.defaultChainId?.description ?? "",
            "dapp_url": loginParams.dappUrl ?? "",
            "chains": web3AuthOptions.chains?.description ?? "[]",
            "auth_ux_mode": "popup"
        ]
        
        // Case 1: No idToken provided
        if loginParams.idToken?.isEmpty ?? true {
            analyticsProps["is_sfa"] = false
            AnalyticsManager.shared.trackEvent(
                AnalyticsEvents.connectionStarted,
                properties: analyticsProps
            )
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
            analyticsProps["is_sfa"] = true
            AnalyticsManager.shared.trackEvent(
                AnalyticsEvents.connectionStarted,
                properties: analyticsProps
            )
            let newLoginParams = LoginParams(
                authConnection: .CUSTOM,
                authConnectionId: groupedId,
                idToken: loginParams.idToken,
                recordId: loginParams.recordId,
                loginSource: loginParams.loginSource
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
            analyticsProps["is_sfa"] = true
            AnalyticsManager.shared.trackEvent(
                AnalyticsEvents.connectionStarted,
                properties: analyticsProps
            )
            KeychainHelper.shared.save(true, forKey: KeychainKeys.isSFA)
            return try await connect(loginParams: loginParams) // SFA login fallback
        }
    }

    
    private func getTorusKey(loginParams: LoginParams, subVerifierInfoArray: [Web3AuthSubVerifierInfo]? = nil) async throws -> TorusKey {
        var retrieveSharesResponse: TorusKey

        let userId = getUserId(from: loginParams.idToken!)
        let details = try await nodeDetailManager.getNodeDetails(verifier: loginParams.authConnectionId!, verifierID: userId!)
        let endpoints = details.getTorusNodeEndpoints()
        let indexes = details.getTorusIndexes()
        let nodePubKeys = details.getTorusNodePub()
        let recordId = loginParams.recordId?.isEmpty == false ? loginParams.recordId! : generateRecordId()
        let authConnection = loginParams.authConnection

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
                params: RetrieveSharesParams(
                    endpoints: endpoints,
                    indexes: indexes,
                    nodePubKeys: nodePubKeys,
                    verifier: loginParams.authConnectionId!,
                    verifierParams: verifierParams,
                    idToken: aggregateIdToken,
                    recordId: recordId,
                    authConnection: authConnection
                )
            )
        } else {
            let verifierParams = VerifierParams(verifier_id: userId!)

            retrieveSharesResponse = try await torusUtils.retrieveShares(
                params: RetrieveSharesParams(
                    endpoints: endpoints,
                    indexes: indexes,
                    nodePubKeys: nodePubKeys,
                    verifier: loginParams.authConnectionId!,
                    verifierParams: verifierParams,
                    idToken: loginParams.idToken!,
                    recordId: recordId,
                    authConnection: authConnection
                )
            )
        }
        
        if retrieveSharesResponse.metadata.upgraded == true {
            throw Web3AuthError.mfaAlreadyEnabled
        }

        return retrieveSharesResponse
    }

    public func connect(loginParams: LoginParams,  subVerifierInfoArray: [Web3AuthSubVerifierInfo]? = nil) async throws -> Web3AuthResponse {
        // Drop any prior PnP citadel tokens so initialize cannot restore the previous user over this SFA session.
        try? await authSessionManager.clearSessionData()

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
                                                    groupedAuthConnectionId: loginParams.groupedAuthConnectionId,
                                                    authConnectionId: loginParams.authConnectionId, userId: jwt.body["user_id"] as? String ?? "",
                                                    dappShare: nil, idToken: nil, oAuthIdToken: nil, oAuthAccessToken: nil, isMfaEnabled: false, authConnection: "custom", appState: nil)
        } catch {
            let duration = Date().timeIntervalSince1970 * 1000 - Double(startTime)

            let properties: [String: Any] = [
                "connector": "auth",
                "auth_connection": loginParams.authConnection,
                "auth_connection_id": loginParams.authConnectionId?.description ?? "",
                "group_auth_connection_id": loginParams.groupedAuthConnectionId?.description ?? "",
                "chain_id": web3AuthOptions.defaultChainId?.description ?? "",
                "dapp_url": loginParams.dappUrl ?? "",
                "chains": web3AuthOptions.chains?.description ?? "[]",
                "auth_ux_mode": "popup",
                "is_sfa": true,
                "duration": duration,
                "error_message": Web3AuthError.inValidLogin
            ]

            AnalyticsManager.shared.trackEvent(AnalyticsEvents.connectionFailed, properties: properties)
            throw Web3AuthError.inValidLogin
        }
        
        let sessionId = try StorageManager<Web3AuthResponse>.generateRandomSessionKey()
        try storageManager.setSessionId(sessionId: sessionId)
        
        let web3AuthResponse = Web3AuthResponse(privateKey: privateKey, ed25519PrivateKey: nil, sessionId: nil, userInfo: decodedUserInfo, error: nil, coreKitKey: nil, coreKitEd25519PrivKey: nil, factorKey: nil, signatures: getSignatureData(sessionTokenData: torusKey.sessionData.sessionTokenData), tssShareIndex: 0, tssPubKey: nil, tssShare: nil, tssTag: nil, tssNonce: 0, nodeIndexes: [], keyMode: nil)
    
        _ = try await storageManager.createSession(data: web3AuthResponse)
        
        StorageManager<Web3AuthResponse>.saveSessionIdToStorage(sessionId)
        try storageManager.setSessionId(sessionId: sessionId)
        self.web3AuthResponse = web3AuthResponse
        var analyticsProps: [String: Any] = [
            "connector": "auth",
            "auth_connection": loginParams.authConnection.description,
            "auth_connection_id": loginParams.authConnectionId?.description ?? "",
            "group_auth_connection_id": loginParams.groupedAuthConnectionId?.description ?? "",
            "chain_id": web3AuthOptions.defaultChainId?.description ?? "",
            "dapp_url": loginParams.dappUrl ?? "",
            "chains": web3AuthOptions.chains?.description ?? "[]",
            "integration_type": web3AuthOptions.getSdkName(),
            "is_sfa": true
        ]

        analyticsProps["duration"] = Int(Date().timeIntervalSince1970) * 1000 - Int(startTime)

        AnalyticsManager.shared.trackEvent(
            AnalyticsEvents.connectionCompleted,
            properties: analyticsProps
        )
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

    @MainActor
    public func enableMFA(_ loginParams: LoginParams? = nil) async throws -> Bool {
        let duration = Date().timeIntervalSince1970 * 1000 - Double(startTime)

        AnalyticsManager.shared.trackEvent(
            AnalyticsEvents.mfaEnablementStarted,
            properties: [
                "integration_type": web3AuthOptions.getSdkName(),
                "dapp_url": loginParams?.dappUrl ?? "",
                "connector": "auth",
                "duration": duration
            ]
        )

        if web3AuthResponse?.userInfo?.isMfaEnabled == true {
            throw Web3AuthError.mfaAlreadyEnabled
        }
        
        if let idToken = self.loginParams?.idToken, !idToken.isEmpty {
            throw Web3AuthError.enabledMfaNotAllowed
        }
        if KeychainHelper.shared.get(forKey: KeychainKeys.isSFA, as: Bool.self) == true {
            throw Web3AuthError.enabledMfaNotAllowed
        }
        guard await hasActiveSession() else {
            throw Web3AuthError.noUserFound
        }
        _ = try await refreshSession()

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
        
        let newSessionId = try StorageManager<Web3AuthResponse>.generateRandomSessionKey()
        let recordId = loginParams?.recordId?.isEmpty == false ? loginParams!.recordId! : generateRecordId()
        let loginSource = resolveLoginSource(loginParams)
        let loginIdObject: [String: String?] = [
            "loginId": newSessionId,
            "platform": web3AuthOptions.getSdkName(),
        ]
        
        let jsonEncoder = JSONEncoder()
        let data = try? jsonEncoder.encode(loginIdObject)
        
        let params: [String: String?] = [
            "authConnection": web3AuthResponse?.userInfo?.authConnection,
            "authConnectionId": web3AuthResponse?.userInfo?.authConnectionId,
            "groupedAuthConnectionId" : web3AuthResponse?.userInfo?.groupedAuthConnectionId,
            "mfaLevel": MFALevel.MANDATORY.rawValue,
            "redirectUrl": redirectUrl,
            "extraLoginOptions": _extraLoginOptions,
            "appState": data?.toBase64URL(),
        ]

        let sessionId = try await authSessionManager.getSessionId() ?? StorageManager<Web3AuthResponse>.getSessionIdFromStorage() ?? ""
        let accessToken = try await authSessionManager.getAccessToken()
        let setUpMFAParams = SetUpMFAParams(options: web3AuthOptions, params: params, actionType: "enable_mfa", sessionId: sessionId, accessToken: accessToken)
        let loginId = try await getLoginId(sessionId: newSessionId, data: setUpMFAParams)

        let jsonObject = makeStartConfigParams(loginId: loginId, recordId: recordId, loginSource: loginSource)

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

                    Task {
                        do {
                            try await self.persistAuthTokens(sessionResponse)
                            let loginDetails = try await self.authorizeSession()
                            if let safeUserInfo = loginDetails.userInfo {
                                KeychainManager.shared.saveDappShare(userInfo: safeUserInfo)
                            }
                            self.web3AuthResponse = loginDetails
                            
                            var analyticsProps: [String: Any] = [
                                "connector": "auth",
                                "auth_connection": loginParams?.authConnection ?? "",
                                "auth_connection_id": loginParams?.authConnectionId?.description ?? "",
                                "group_auth_connection_id": loginParams?.groupedAuthConnectionId?.description ?? "",
                                "chain_id": self.web3AuthOptions.defaultChainId?.description ?? "",
                                "dapp_url": loginParams?.dappUrl ?? "",
                                "chains": self.web3AuthOptions.chains?.description ?? "[]",
                                "integration_type": self.web3AuthOptions.getSdkName(),
                                "is_sfa": false
                            ]

                            analyticsProps["duration"] = Int(Date().timeIntervalSince1970) * 1000 - Int(self.startTime)

                            AnalyticsManager.shared.trackEvent(
                                AnalyticsEvents.mfaEnablementCompleted,
                                properties: analyticsProps
                            )
                            
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
    }
    
    @MainActor
    public func manageMFA(_ loginParams: LoginParams? = nil) async throws -> Bool {
        AnalyticsManager.shared.trackEvent(
            AnalyticsEvents.mfaManagementStarted,
            properties: [
                "integration_type": web3AuthOptions.getSdkName(),
                "dapp_url": loginParams?.dappUrl ?? "",
                "connector": "auth"
            ]
        )
        AnalyticsManager.shared.trackEvent(AnalyticsEvents.mfaManagementSelected)
        if web3AuthResponse?.userInfo?.isMfaEnabled == false {
            throw Web3AuthError.mfaNotEnabled
        }
        
        if let idToken = self.loginParams?.idToken, !idToken.isEmpty {
            throw Web3AuthError.enabledMfaNotAllowed
        }
        if KeychainHelper.shared.get(forKey: KeychainKeys.isSFA, as: Bool.self) == true {
            throw Web3AuthError.enabledMfaNotAllowed
        }
        guard await hasActiveSession() else {
            throw Web3AuthError.noUserFound
        }
        _ = try await refreshSession()

        var modifiedLoginParams = self.loginParams
        var modifiedInitParams = web3AuthOptions

        if loginParams != nil {
            modifiedLoginParams = loginParams
        }

        var extraLoginOptions: ExtraLoginOptions? = modifiedLoginParams?.extraLoginOptions ?? loginParams?.extraLoginOptions ?? ExtraLoginOptions()
        extraLoginOptions?.login_hint = web3AuthResponse?.userInfo?.userId

        let jsonData = try? JSONEncoder().encode(extraLoginOptions)
        let _extraLoginOptions = jsonData.flatMap { String(data: $0, encoding: .utf8) }
        
        let newSessionId = try StorageManager<Web3AuthResponse>.generateRandomSessionKey()
        let recordId = loginParams?.recordId?.isEmpty == false ? loginParams!.recordId! : generateRecordId()
        let loginSource = resolveLoginSource(loginParams)
        let loginIdObject: [String: String?] = [
            "loginId": newSessionId,
            "recordId": recordId,
        ]
        
        let jsonEncoder = JSONEncoder()
        let data = try? jsonEncoder.encode(loginIdObject)
        
        let dappUrl = self.web3AuthOptions.redirectUrl
        
        let params: [String: String?] = [
            "authConnection": web3AuthResponse?.userInfo?.authConnection,
            "authConnectionId": web3AuthResponse?.userInfo?.authConnectionId,
            "groupedAuthConnectionId" : web3AuthResponse?.userInfo?.groupedAuthConnectionId,
            "mfaLevel": MFALevel.MANDATORY.rawValue,
            "redirectUrl": modifiedInitParams.dashboardUrl,
            "extraLoginOptions": _extraLoginOptions,
            "appState": data?.toBase64URL(),
            "dappUrl": dappUrl
        ]
        
        modifiedInitParams.redirectUrl = modifiedInitParams.dashboardUrl!

        let sessionId = try await authSessionManager.getSessionId() ?? StorageManager<Web3AuthResponse>.getSessionIdFromStorage() ?? ""
        let accessToken = try await authSessionManager.getAccessToken()
        let setUpMFAParams = SetUpMFAParams(options: modifiedInitParams, params: params, actionType: "manage_mfa", sessionId: sessionId, accessToken: accessToken)
        let loginId = try await getLoginId(sessionId: newSessionId, data: setUpMFAParams)

        let jsonObject = makeStartConfigParams(loginId: loginId, recordId: recordId, loginSource: loginSource)

        let url = try Web3Auth.generateAuthSessionURL(web3AuthOptions: modifiedInitParams, jsonObject: jsonObject, sdkUrl: modifiedInitParams.sdkUrl, path: "start")

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            DispatchQueue.main.async {
                self.authSession = ASWebAuthenticationSession(
                    url: url, callbackURLScheme: URL(string: dappUrl)?.scheme
                ) { callbackURL, authError in
                    if let authError = authError {
                        if case ASWebAuthenticationSessionError.canceledLogin = authError {
                            continuation.resume(throwing: Web3AuthError.userCancelled)
                        } else {
                            continuation.resume(throwing: authError)
                        }
                        return
                    }

                    Task {
                        if let callbackURL,
                           let redirect = try? Web3Auth.decodeRedirectFromCallbackURL(callbackURL),
                           redirect.actionType == "manage_mfa",
                           let sessionId = redirect.sessionId, !sessionId.isEmpty {
                            try? await self.persistAuthTokens(SessionResponse(
                                sessionId: sessionId,
                                accessToken: redirect.accessToken,
                                refreshToken: redirect.refreshToken,
                                idToken: redirect.idToken
                            ))
                        }

                        var analyticsProps: [String: Any] = [
                            "connector": "auth",
                            "auth_connection": loginParams?.authConnection ?? "",
                            "auth_connection_id": loginParams?.authConnectionId?.description ?? "",
                            "group_auth_connection_id": loginParams?.groupedAuthConnectionId?.description ?? "",
                            "chain_id": self.web3AuthOptions.defaultChainId?.description ?? "",
                            "dapp_url": loginParams?.dappUrl ?? "",
                            "chains": self.web3AuthOptions.chains?.description ?? "[]",
                            "integration_type": self.web3AuthOptions.getSdkName(),
                            "is_sfa": false
                        ]

                        analyticsProps["duration"] = Int(Date().timeIntervalSince1970) * 1000 - Int(self.startTime)

                        AnalyticsManager.shared.trackEvent(
                            AnalyticsEvents.mfaManagementCompleted,
                            properties: analyticsProps
                        )

                        continuation.resume(returning: true)
                    }
                }

                self.authSession?.presentationContextProvider = self

                if !(self.authSession?.start() ?? false) {
                    let duration = Date().timeIntervalSince1970 * 1000 - Double(self.startTime)

                    AnalyticsManager.shared.trackEvent(
                        AnalyticsEvents.mfaManagementFailed,
                        properties: [
                            "duration": duration,
                            "error_message": "MFA Enablement Failed: Web3AuthError.unknownError"
                        ]
                    )
                    continuation.resume(throwing: Web3AuthError.unknownError)
                }
            }
        }
    }
    
    @MainActor
    public func showWalletUI(path: String? = "wallet") async throws {
        AnalyticsManager.shared.trackEvent(
            AnalyticsEvents.walletUIClicked,
            properties: [
                "integration_type": web3AuthOptions.getSdkName(),
                "dapp_url": loginParams?.dappUrl ?? ""
            ]
        )
        try requireActiveKeys()
        let creds = try await resolveWalletLaunchCreds()
        var initOptionsJson = try JSONSerialization.jsonObject(with: JSONEncoder().encode(web3AuthOptions)) as! [String: Any]
        try applyProjectConfigToWalletOptions(&initOptionsJson)

        let paramMap: [String: Any] = [
            "options": initOptionsJson
        ]

        let sessionId = try StorageManager<Web3AuthResponse>.generateRandomSessionKey()
        let jsonData = try JSONSerialization.data(withJSONObject: paramMap)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let loginId = try await getLoginId(sessionId: sessionId, data: jsonString)

        var jsonObject: [String: String?] = [
            "loginId": loginId?.strip0xForWalletSession(),
            "sessionId": creds.sessionId.strip0xForWalletSession(),
            "platform": "ios",
        ]
        jsonObject["accessToken"] = creds.accessToken
        jsonObject["idToken"] = creds.idToken
        jsonObject["refreshToken"] = creds.refreshToken
        
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
    }

    @MainActor
    public func request(method: String, requestParams: [Any], path: String? = "wallet/request", appState: String? = nil) async throws -> SignResponse? {
        AnalyticsManager.shared.trackEvent(
            AnalyticsEvents.requestFunctionStarted
        )
        try requireActiveKeys()
        let creds = try await resolveWalletLaunchCreds()
        var initOptionsJson = try JSONSerialization.jsonObject(with: JSONEncoder().encode(web3AuthOptions)) as! [String: Any]
        try applyProjectConfigToWalletOptions(&initOptionsJson)

        let paramMap: [String: Any] = [
            "options": initOptionsJson
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: paramMap)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let loginId = try StorageManager<Web3AuthResponse>.generateRandomSessionKey()
        let _loginId = try await getLoginId(sessionId: loginId, data: jsonString)

        var signMessageMap: [String: String] = [:]
        signMessageMap["loginId"] = _loginId?.strip0xForWalletSession()
        signMessageMap["sessionId"] = creds.sessionId.strip0xForWalletSession()
        signMessageMap["platform"] = "ios"
        if let appState, !appState.isEmpty {
            signMessageMap["appState"] = appState
        }
        if let accessToken = creds.accessToken {
            signMessageMap["accessToken"] = accessToken
        }
        if let idToken = creds.idToken {
            signMessageMap["idToken"] = idToken
        }
        if let refreshToken = creds.refreshToken {
            signMessageMap["refreshToken"] = refreshToken
        }
        
        if let isSFA = KeychainHelper.shared.get(forKey: "isSFA", as: Bool.self), isSFA {
            signMessageMap["sessionNamespace"] = "sfa"
        }

        var requestData: [String: Any] = [:]
        requestData["method"] = method
        requestData["params"] = try? JSONSerialization.jsonObject(with: JSONSerialization.data(withJSONObject: requestParams), options: []) as? [Any]

        if let requestDataJson = try? JSONSerialization.data(withJSONObject: requestData, options: []),
           let requestDataJsonString = String(data: requestDataJson, encoding: .utf8) {
            signMessageMap["request"] = requestDataJsonString
        }

        let url = try Web3Auth.generateAuthSessionURL(web3AuthOptions: web3AuthOptions, jsonObject: signMessageMap, sdkUrl: web3AuthOptions.walletSdkUrl,
                                                      path: path)

        return await withCheckedContinuation { continuation in
            Task {
                let webViewController = await MainActor.run {
                    WebViewController(redirectUrl: web3AuthOptions.redirectUrl, onSignResponse: { signResponse in
                        let duration = Date().timeIntervalSince1970 * 1000 - Double(self.startTime)
                        AnalyticsManager.shared.trackEvent(
                            AnalyticsEvents.requestFunctionCompleted,
                            properties: [
                                "duration": duration
                            ]
                        )

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
        guard let callbackData = try callbackFragmentData(callbackURL) else {
            throw Web3AuthError.decodingError
        }

        guard let callbackState = try? JSONDecoder().decode(SessionResponse.self, from: callbackData) else {
            throw Web3AuthError.decodingError
        }

        return callbackState
    }

    static func decodeRedirectFromCallbackURL(_ callbackURL: URL) throws -> RedirectResponse {
        guard let callbackData = try callbackFragmentData(callbackURL) else {
            throw Web3AuthError.decodingError
        }
        guard let callbackState = try? JSONDecoder().decode(RedirectResponse.self, from: callbackData) else {
            throw Web3AuthError.decodingError
        }
        return callbackState
    }

    private static func callbackFragmentData(_ callbackURL: URL) throws -> Data? {
        guard
            let host = callbackURL.host,
            let fragment = callbackURL.fragment,
            let component = URLComponents(string: host + "?" + fragment),
            let queryItems = component.queryItems,
            let b64ParamsItem = queryItems.first(where: { $0.name == "b64Params" }),
            let callbackFragment = b64ParamsItem.value
        else {
            throw Web3AuthError.decodingError
        }
        return Data.fromBase64URL(callbackFragment)
    }


    static func decodeSessionStringfromCallbackURL(_ callbackURL: URL) throws -> String? {
        let callbackFragment = callbackURL.fragment
        return callbackFragment?.components(separatedBy: "&")[0].components(separatedBy: "=")[1]
    }

    public func fetchProjectConfig() async throws -> Bool {
        var response: Bool = false
        var queryItems = [
            URLQueryItem(name: "project_id", value: web3AuthOptions.clientId),
            URLQueryItem(name: "network", value: web3AuthOptions.web3AuthNetwork.name),
            URLQueryItem(name: "build_env", value: web3AuthOptions.authBuildEnv?.rawValue)
        ]
        if let aaProvider = resolveAaProvider() {
            queryItems.append(URLQueryItem(name: "aa_provider", value: aaProvider))
        }
        let api = Router.get(queryItems)
        let result = await Service.request(router: api)
        switch result {
        case let .success(data):
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(ProjectConfigResponse.self, from: data)
                projectConfigResponse = result
                AnalyticsManager.shared.setGlobalProperties([
                    "sdk_name": web3AuthOptions.getSdkName(),
                    "sdk_version": web3AuthOptions.getSdkVersion(),
                    "web3auth_client_id": web3AuthOptions.clientId,
                    "web3auth_network": web3AuthOptions.web3AuthNetwork,
                    "team_id" : "\(projectConfigResponse?.teamId ?? 0)",
                    "integration_type": AnalyticsIntegrationType.nativeSDK
                ])

                applySessionTimeFromProjectConfig(result)
                applySmartAccountFlagsFromProjectConfig(result)
                
                AnalyticsManager.shared.trackEvent(
                    AnalyticsEvents.sdkInitializationCompleted,
                    properties: buildInitializationAnalyticsProperties()
                )
                
                web3AuthOptions.originData = result.whitelist.signedUrls.merging(web3AuthOptions.originData ?? [:]) { _, new in new }
                web3AuthOptions.authConnectionConfig =
                    (web3AuthOptions.authConnectionConfig ?? []) + (projectConfigResponse?.embeddedWalletAuth ?? [])
                web3AuthOptions.mfaSettings = web3AuthOptions.mfaSettings?.merge(with: projectConfigResponse?.mfaSettings)
                    ?? projectConfigResponse?.mfaSettings
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
                if web3AuthOptions.chains == nil {
                    web3AuthOptions.chains = result.chains
                }
                mergeWalletServicesFromProjectConfig(result)
                response = true
            } catch {
                let duration = Int(Date().timeIntervalSince1970 * 1000) - Int(startTime)
                let properties: [String: Any] = [
                    "integration_type": AnalyticsIntegrationType.nativeSDK,
                    "dapp_url": self.loginParams?.dappUrl ?? "",
                    "duration": duration,
                    "error_code": "PROJECT_CONFIG_NOT_FOUND_ERROR",
                    "error_message": error
                ]

                AnalyticsManager.shared.trackEvent(AnalyticsEvents.sdkInitializationFailed, properties: properties)

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

    public func getEd25519PrivateKey() throws -> String {
        guard let web3AuthResponse = web3AuthResponse else {
            throw Web3AuthError.noUserFound
        }

        if web3AuthOptions.useSFAKey == true {
            // Check if isDefault == false, throw error
            if let embeddedWalletAuth = projectConfigResponse?.embeddedWalletAuth,
               let matchedAuth = embeddedWalletAuth.first(where: { $0.authConnectionId == web3AuthResponse.userInfo?.authConnectionId }),
               matchedAuth.isDefault == false {
                throw Web3AuthError.ed25519CustomAuthError
            }

            // Return coreKit Ed25519 private key
            if let key = web3AuthResponse.coreKitEd25519PrivKey, !key.isEmpty {
                return key
            }
        } else {
            // Return regular Ed25519 private key
            if let key = web3AuthResponse.ed25519PrivateKey, !key.isEmpty {
                return key
            }
        }

        throw Web3AuthError.ed25519KeyNotFound
    }

    public func getUserInfo() throws -> Web3AuthUserInfo {
        guard let web3AuthResponse = web3AuthResponse, let userInfo = web3AuthResponse.userInfo else { throw Web3AuthError.noUserFound }
        return userInfo
    }

    /// Auth v11 parity: returns user info and backfills `idToken` from citadel storage when missing.
    public func getUserInfoAsync() async throws -> Web3AuthUserInfo {
        guard var userInfo = web3AuthResponse?.userInfo else { throw Web3AuthError.noUserFound }
        if userInfo.idToken == nil || userInfo.idToken?.isEmpty == true,
           let idToken = try await authSessionManager.getIdToken(), !idToken.isEmpty {
            userInfo.idToken = idToken
        }
        return userInfo
    }

    public func getAccessToken() async throws -> String {
        guard let token = try await authSessionManager.getAccessToken(), !token.isEmpty else {
            throw Web3AuthError.noUserFound
        }
        return token
    }

    public func getIdentityToken() async throws -> String {
        AnalyticsManager.shared.trackEvent(AnalyticsEvents.identityTokenStarted)
        do {
            guard let token = try await authSessionManager.getIdToken(), !token.isEmpty else {
                throw Web3AuthError.noUserFound
            }
            AnalyticsManager.shared.trackEvent(AnalyticsEvents.identityTokenCompleted)
            return token
        } catch {
            AnalyticsManager.shared.trackEvent(
                AnalyticsEvents.identityTokenFailed,
                properties: ["error_message": "\(error)"]
            )
            throw error
        }
    }

    /// Re-authorizes the current citadel session. Clears tokens on failure.
    public func refreshSession() async throws -> Web3AuthResponse {
        do {
            let response = try await authorizeSession()
            web3AuthResponse = response
            return response
        } catch {
            try? await authSessionManager.logout()
            web3AuthResponse = nil
            throw error
        }
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

private extension Web3Auth {
    static func makeStorageManager(options: Web3AuthOptions, sessionNamespace: String?, sessionId: String? = nil) throws -> StorageManager<Web3AuthResponse> {
        guard let url = options.storageServerUrl, !url.isEmpty else {
            throw Web3AuthError.runtimeError("storageServerUrl is required")
        }
        return try StorageManager<Web3AuthResponse>(
            sessionServerBaseUrl: url,
            sessionNamespace: sessionNamespace,
            sessionTime: options.sessionTime ?? DEFAULT_SESSION_TIME,
            sessionId: sessionId,
            allowedOrigin: options.redirectUrl
        )
    }

    static func makeAuthSessionManager(options: Web3AuthOptions) -> AuthSessionManager<Web3AuthResponse> {
        let citadelUrl = options.citadelServerUrl ?? Web3AuthUrls.citadelServerUrl(options.authBuildEnv)
        return AuthSessionManager<Web3AuthResponse>(apiClientConfig: ApiClientConfig(baseURL: citadelUrl))
    }

    static func toFndBuildEnv(_ buildEnv: BuildEnv?) -> FetchNodeDetails.BuildEnv {
        switch buildEnv {
        case .staging: return .staging
        case .testing: return .testing
        default: return .production
        }
    }

    static func resolveSessionNamespace(from options: Web3AuthOptions) -> String? {
        if let namespace = options.sessionNamespace, !namespace.isEmpty {
            return namespace
        }
        let isSFA = KeychainHelper.shared.get(forKey: KeychainKeys.isSFA, as: Bool.self) ?? false
        return isSFA ? "sfa" : nil
    }

    func createStorageManager<T: Codable>(sessionNamespace: String?, sessionId: String? = nil) throws -> StorageManager<T> {
        guard let url = web3AuthOptions.storageServerUrl, !url.isEmpty else {
            throw Web3AuthError.runtimeError("storageServerUrl is required")
        }
        return try StorageManager<T>(
            sessionServerBaseUrl: url,
            sessionNamespace: sessionNamespace,
            sessionTime: web3AuthOptions.sessionTime ?? DEFAULT_SESSION_TIME,
            sessionId: sessionId,
            allowedOrigin: web3AuthOptions.redirectUrl
        )
    }

    func createAuthSessionManager() -> AuthSessionManager<Web3AuthResponse> {
        Web3Auth.makeAuthSessionManager(options: web3AuthOptions)
    }

    func generateRecordId() -> String {
        UUID().uuidString
    }

    func resolveSessionNamespace() -> String? {
        Web3Auth.resolveSessionNamespace(from: web3AuthOptions)
    }

    func resolveLoginSource(_ params: LoginParams?) -> String {
        if let loginSource = params?.loginSource, !loginSource.isEmpty {
            return loginSource
        }
        return web3AuthOptions.isFlutterAnalytics ? LOGIN_SOURCE_FLUTTER : LOGIN_SOURCE_IOS
    }

    func makeStartConfigParams(loginId: String?, recordId: String, loginSource: String) -> [String: String?] {
        var config: [String: String?] = [
            "loginId": loginId,
            "recordId": recordId,
            "loginSource": loginSource
        ]
        if let namespace = resolveSessionNamespace(), !namespace.isEmpty {
            config["sessionNamespace"] = namespace
        }
        config["storageServerUrl"] = web3AuthOptions.storageServerUrl
        return config
    }

    func persistAuthTokens(_ sessionResponse: SessionResponse) async throws {
        StorageManager<Web3AuthResponse>.saveSessionIdToStorage(sessionResponse.sessionId)
        try await authSessionManager.setTokens(AuthTokens(
            sessionId: sessionResponse.sessionId,
            accessToken: sessionResponse.accessToken,
            refreshToken: sessionResponse.refreshToken,
            idToken: sessionResponse.idToken
        ))
    }

    /// Android `authorize()` returns decrypted JSON and Gson-parses it. Swift
    /// `AuthSessionManager<T>.authorize()` swallows decrypt/decode errors and
    /// returns nil, so we refresh + decrypt ourselves and parse like Android.
    func authorizeSession() async throws -> Web3AuthResponse {
        if let response = try await authorizeFromCitadel() {
            try validateAuthorizedResponse(response)
            web3AuthResponse = response
            return response
        }
        let savedSessionId = StorageManager<Web3AuthResponse>.getSessionIdFromStorage() ?? ""
        guard !savedSessionId.isEmpty else {
            throw Web3AuthError.noUserFound
        }
        try storageManager.setSessionId(sessionId: savedSessionId)
        do {
            let response = try await storageManager.authorizeSession()
            try validateAuthorizedResponse(response)
            web3AuthResponse = response
            return response
        } catch {
            throw Web3AuthError.noUserFound
        }
    }

    func authorizeFromCitadel() async throws -> Web3AuthResponse? {
        let sessionId = try await authSessionManager.getSessionId()
        let accessToken = try await authSessionManager.getAccessToken()
        let refreshToken = try await authSessionManager.getRefreshToken()
        guard let sessionId, !sessionId.isEmpty, accessToken != nil || refreshToken != nil else {
            return nil
        }
        do {
            let refresh = try await authSessionManager.ensureRefresh(skipIfFresh: false)
            return try decodeCitadelSession(sessionId: sessionId, sessionData: refresh.session_data)
        } catch {
            return nil
        }
    }

    func decodeCitadelSession(sessionId: String, sessionData: String) throws -> Web3AuthResponse {
        if let decoded: Web3AuthResponse = try? CryptoHelpers.decryptData(privKeyHex: sessionId, d: sessionData) {
            return decoded
        }
        let dict: [String: Any] = try CryptoHelpers.decryptData(privKeyHex: sessionId, d: sessionData)
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let decoded = try? JSONDecoder().decode(Web3AuthResponse.self, from: data) {
            return decoded
        }
        return Web3AuthResponse(
            privateKey: dict["privKey"] as? String,
            ed25519PrivateKey: dict["ed25519PrivKey"] as? String,
            sessionId: dict["sessionId"] as? String ?? sessionId,
            userInfo: (dict["userInfo"] as? [String: Any]).flatMap { Web3AuthUserInfo(dict: $0) },
            error: dict["error"] as? String,
            coreKitKey: dict["coreKitKey"] as? String,
            coreKitEd25519PrivKey: dict["coreKitEd25519PrivKey"] as? String,
            factorKey: dict["factorKey"] as? String,
            signatures: dict["signatures"] as? [String],
            tssShareIndex: dict["tssShareIndex"] as? Int,
            tssPubKey: dict["tssPubKey"] as? String,
            tssShare: dict["tssShare"] as? String,
            tssTag: dict["tssTag"] as? String,
            tssNonce: dict["tssNonce"] as? Int,
            nodeIndexes: dict["nodeIndexes"] as? [Int],
            keyMode: dict["keyMode"] as? String
        )
    }

    func validateAuthorizedResponse(_ response: Web3AuthResponse) throws {
        if let error = response.error, !error.isEmpty {
            throw Web3AuthError.runtimeError(error)
        }
        if (response.privateKey?.isEmpty ?? true) && (response.factorKey?.isEmpty ?? true) {
            throw Web3AuthError.unknownError
        }
    }

    func hasActiveSession() async -> Bool {
        if let sessionId = try? await authSessionManager.getSessionId(), !sessionId.isEmpty {
            return true
        }
        let storageSessionId = StorageManager<Web3AuthResponse>.getSessionIdFromStorage() ?? ""
        let hasKeys = !(web3AuthResponse?.privateKey?.isEmpty ?? true) || !(web3AuthResponse?.factorKey?.isEmpty ?? true)
        return !storageSessionId.isEmpty || hasKeys
    }

    func requireActiveKeys() throws {
        guard let response = web3AuthResponse,
              !(response.privateKey?.isEmpty ?? true) || !(response.factorKey?.isEmpty ?? true) else {
            AnalyticsManager.shared.trackEvent(
                AnalyticsEvents.walletServicesFailed,
                properties: [
                    "integration_type": web3AuthOptions.getSdkName(),
                    "dapp_url": loginParams?.dappUrl ?? "",
                    "duration": Int(Date().timeIntervalSince1970 * 1000) - Int(startTime),
                    "error": "Wallet Services Error: SessionId not found. Please login first."
                ]
            )
            throw Web3AuthError.runtimeError("Please login first to launch wallet")
        }
    }

    private func resolveWalletLaunchCreds() async throws -> WalletLaunchCreds {
        let citadelSession = try await authSessionManager.getSessionId()
        let accessToken = try await authSessionManager.getAccessToken()
        let idToken = try await authSessionManager.getIdToken()
        let refreshToken = try await authSessionManager.getRefreshToken()
        let sessionId = (citadelSession?.isEmpty == false ? citadelSession : StorageManager<Web3AuthResponse>.getSessionIdFromStorage()) ?? ""
        guard !sessionId.isEmpty else {
            throw Web3AuthError.runtimeError("Please login first to launch wallet")
        }
        let isSfa = KeychainHelper.shared.get(forKey: KeychainKeys.isSFA, as: Bool.self) ?? false
        if !isSfa && (accessToken == nil || accessToken?.isEmpty == true) {
            throw Web3AuthError.runtimeError("Missing accessToken for wallet services. Please login again.")
        }
        return WalletLaunchCreds(
            sessionId: sessionId,
            accessToken: accessToken?.isEmpty == false ? accessToken : nil,
            idToken: idToken?.isEmpty == false ? idToken : nil,
            refreshToken: refreshToken?.isEmpty == false ? refreshToken : nil
        )
    }

    func applyProjectConfigToWalletOptions(_ initOptionsJson: inout [String: Any]) throws {
        if projectConfigResponse?.chains == nil {
            throw Web3AuthError.runtimeError("Project config not found")
        }
        if let chains = projectConfigResponse?.chains {
            let chainsData = try JSONEncoder().encode(chains)
            let chainsJson = try JSONSerialization.jsonObject(with: chainsData) as! [Any]
            initOptionsJson["chains"] = chainsJson
            initOptionsJson["chainId"] = chains.first?.chainId ?? web3AuthOptions.defaultChainId ?? "0x1"
            initOptionsJson["defaultChainId"] = chains.first?.chainId ?? web3AuthOptions.defaultChainId ?? "0x1"
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

        if let walletServicesConfig = web3AuthOptions.walletServicesConfig {
            let wsData = try JSONEncoder().encode(walletServicesConfig)
            initOptionsJson["walletServicesConfig"] = try JSONSerialization.jsonObject(with: wsData)
        }

        if let walletConnectProjectId = projectConfigResponse?.walletConnectProjectId, !walletConnectProjectId.isEmpty {
            initOptionsJson["walletConnectProjectId"] = walletConnectProjectId
        }
    }

    func resolveAaProvider() -> String? {
        guard let raw = web3AuthOptions.accountAbstractionConfig,
              let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let keys = ["smartAccountType", "smart_account_type", "aaProvider", "aa_provider"]
        for key in keys {
            if let value = json[key] as? String, !value.isEmpty {
                return value.lowercased()
            }
        }
        return nil
    }

    func applySessionTimeFromProjectConfig(_ response: ProjectConfigResponse?) {
        if web3AuthOptions.sessionTime == nil {
            let fromProject = response?.sessionTime.flatMap { $0 > 0 ? $0 : nil }
            web3AuthOptions.sessionTime = fromProject ?? DEFAULT_SESSION_TIME
        }
        if let rebuilt = try? Web3Auth.makeStorageManager(options: web3AuthOptions, sessionNamespace: resolveSessionNamespace()) {
            storageManager = rebuilt
        }
    }

    func applySmartAccountFlagsFromProjectConfig(_ response: ProjectConfigResponse?) {
        guard let smartAccounts = response?.smartAccounts else { return }
        if web3AuthOptions.useAAWithExternalWallet == nil {
            web3AuthOptions.useAAWithExternalWallet = smartAccounts.walletScope == .all
        }
        if web3AuthOptions.accountAbstractionConfig == nil || web3AuthOptions.accountAbstractionConfig?.isEmpty == true,
           let data = try? JSONEncoder().encode(smartAccounts),
           let json = String(data: data, encoding: .utf8) {
            web3AuthOptions.accountAbstractionConfig = json
        }
    }

    func buildInitializationAnalyticsProperties() -> [String: Any] {
        let projectChains = projectConfigResponse?.chains
        let optionChain = web3AuthOptions.chains
        let chainIds = projectChains?.compactMap { $0.chainId } ?? optionChain?.compactMap { $0.chainId } ?? []
        let defaultChainId = web3AuthOptions.defaultChainId
            ?? projectChains?.first?.chainId
            ?? optionChain?.first?.chainId
            ?? "0x1"
        let wl = web3AuthOptions.whiteLabel
        let ws = web3AuthOptions.walletServicesConfig
        let sa = projectConfigResponse?.smartAccounts
        return [
            "chain_ids": chainIds,
            "chain_names": projectChains?.compactMap { $0.displayName } ?? optionChain?.compactMap { $0.displayName } ?? [],
            "chain_rpc_targets": projectChains?.map { $0.rpcTarget } ?? optionChain?.map { $0.rpcTarget } ?? [],
            "default_chain_id": defaultChainId,
            "chain_nameSpaces": ["eip155", "solana", "other"],
            "session_time": web3AuthOptions.sessionTime ?? DEFAULT_SESSION_TIME,
            "sfa_key_enabled": web3AuthOptions.useSFAKey ?? false,
            "logging_enabled": web3AuthOptions.enableLogging ?? false,
            "auth_build_env": web3AuthOptions.authBuildEnv?.rawValue ?? "",
            "whitelabel_logo_light_enabled": wl?.logoLight != nil,
            "whitelabel_logo_dark_enabled": wl?.logoDark != nil,
            "whitelabel_theme_mode": wl?.theme as Any,
            "whitelabel_app_name": wl?.appName as Any,
            "whitelabel_tnc_link_enabled": !(wl?.tncLink?.isEmpty ?? true),
            "whitelabel_privacy_policy_enabled": !(wl?.privacyPolicy?.isEmpty ?? true),
            "whitelabel_consent_required": wl?.consentRequired ?? false,
            "aa_smart_account_type": sa?.smartAccountType.rawValue as Any,
            "aa_eip_standard": sa?.eipStandard as Any,
            "aa_wallet_scope": sa?.walletScope?.rawValue as Any,
            "aa_use_with_external_wallet": web3AuthOptions.useAAWithExternalWallet as Any,
            "ws_confirmation_strategy": ws?.confirmationStrategy?.rawValue as Any,
            "ws_enable_key_export": ws?.enableKeyExport as Any,
            "duration": Int(Date().timeIntervalSince1970 * 1000) - Int(startTime),
            "integration_type": AnalyticsIntegrationType.nativeSDK,
            "dapp_url": loginParams?.dappUrl as Any
        ]
    }

    func mergeWalletServicesFromProjectConfig(_ response: ProjectConfigResponse?) {
        guard let walletUi = response?.walletUiConfig else { return }
        let existing = web3AuthOptions.walletServicesConfig
        var whiteLabelMap: [String: String] = existing?.whiteLabel?.theme ?? [:]

        func putBool(_ key: String, invertedEnable: Bool?) {
            if let invertedEnable {
                whiteLabelMap[key] = (!invertedEnable).description
            }
        }

        putBool("hideTokenDisplay", invertedEnable: walletUi.enableTokenDisplay)
        putBool("hideNftDisplay", invertedEnable: walletUi.enableNftDisplay)
        putBool("hideTransfers", invertedEnable: walletUi.enableSendButton)
        putBool("hideTopup", invertedEnable: walletUi.enableBuyButton)
        putBool("hideReceive", invertedEnable: walletUi.enableReceiveButton)
        putBool("hideSwap", invertedEnable: walletUi.enableSwapButton)
        putBool("hideShowAllTokens", invertedEnable: walletUi.enableShowAllTokensButton)
        putBool("hideWalletConnect", invertedEnable: walletUi.enableWalletConnect)
        putBool("hideDefiPositionsDisplay", invertedEnable: walletUi.enableDefiPositionsDisplay)
        if let enablePortfolioWidget = walletUi.enablePortfolioWidget {
            whiteLabelMap["showWidgetButton"] = enablePortfolioWidget.description
        }
        if let position = walletUi.portfolioWidgetPosition {
            whiteLabelMap["buttonPosition"] = position.rawValue
        }
        if let portfolio = walletUi.defaultPortfolio {
            whiteLabelMap["defaultPortfolio"] = portfolio.rawValue
        }

        let confirmation: ConfirmationStrategy
        if let enableModal = walletUi.enableConfirmationModal {
            confirmation = enableModal ? .modal : .autoApprove
        } else {
            confirmation = existing?.confirmationStrategy ?? .defaultStrategy
        }

        var mergedWhiteLabel = (existing?.whiteLabel ?? web3AuthOptions.whiteLabel) ?? WhiteLabelData()
        mergedWhiteLabel.theme = whiteLabelMap.isEmpty ? existing?.whiteLabel?.theme : whiteLabelMap
        if let existingWhiteLabel = existing?.whiteLabel {
            mergedWhiteLabel = existingWhiteLabel.merge(with: mergedWhiteLabel)
        }

        web3AuthOptions.walletServicesConfig = WalletServicesConfig(
            confirmationStrategy: existing?.confirmationStrategy ?? confirmation,
            whiteLabel: mergedWhiteLabel,
            enableKeyExport: existing?.enableKeyExport ?? response?.enableKeyExport
        )
    }
}
