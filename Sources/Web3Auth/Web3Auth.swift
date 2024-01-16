import AuthenticationServices
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
    var webViewController: WebViewController = WebViewController()
    /**
     Web3Auth  component for authenticating with web-based flow.

     ```
     Web3Auth(OLInitParams(clientId: clientId, network: .mainnet))
     ```

     - parameter params: Init params for your Web3Auth instance.

     - returns: Web3Auth component.
     */
    public init(_ params: W3AInitParams) async {
        initParams = params
        sessionManager = .init()
            do {
                let loginDetailsDict = try await sessionManager.authorizeSession()
                guard let loginDetails = Web3AuthState(dict: loginDetailsDict, sessionID: sessionManager.getSessionID() ?? "",
                network: initParams.network) else { throw Web3AuthError.decodingError }
                state = loginDetails
            } catch let error {
                os_log("%s", log: getTorusLogger(log: Web3AuthLogger.core, type: .error), type: .error, error.localizedDescription)
            }
        super.init()
    }

    public func logout() async throws {
        guard let state = state else {throw Web3AuthError.noUserFound}
        try await sessionManager.invalidateSession()
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
    public convenience init(_ bundle: Bundle = Bundle.main) async {
        let values = plistValues(bundle)!
        await self.init(W3AInitParams(clientId: values.clientId, network: values.network))
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
        var loginParams = loginParams
        //assign loginParams redirectUrl from intiParamas redirectUrl
        loginParams.redirectUrl = "\(bundleId)://auth"
        if let loginConfig = initParams.loginConfig?.values.first,
           let savedDappShare = KeychainManager.shared.getDappShare(verifier: loginConfig.verifier) {
            loginParams.dappShare = savedDappShare
        }
        
        let sdkUrlParams = SdkUrlParams(options: initParams, params: loginParams, actionType: "login")

        let loginId = try await getLoginId(data: sdkUrlParams)
        
        let jsonObject: [String: String?] = [
            "loginId": loginId
        ]

        let url = try Web3Auth.generateAuthSessionURL(initParams: initParams, jsonObject: jsonObject, isWalletServices: false)
        
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Web3AuthState, Error>) in

            authSession = ASWebAuthenticationSession(
                url: url, callbackURLScheme: redirectURL.scheme) { callbackURL, authError in

                    guard
                        authError == nil,
                        let callbackURL = callbackURL,
                        let sessionId = try? Web3Auth.decodeSessionStringfromCallbackURL(callbackURL)
                    else {
                        let authError = authError ?? Web3AuthError.unknownError
                        if case ASWebAuthenticationSessionError.canceledLogin = authError {
                            continuation.resume(throwing: Web3AuthError.userCancelled)
                        } else {
                            continuation.resume(throwing: authError)
                        }
                        return
                    }
                    
                    self.sessionManager.setSessionID(sessionId)
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
    
    public func setupMFA(_ loginParams: W3ALoginParams) async throws -> Bool{
        let sessionId = self.sessionManager.getSessionID()
        if !(sessionId ?? "").isEmpty {
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let redirectURL = URL(string: "\(bundleId)://auth")
            else { throw Web3AuthError.noBundleIdentifierFound }
            var loginParams = loginParams
            //assign loginParams redirectUrl from intiParamas redirectUrl
            loginParams.redirectUrl = "\(bundleId)://auth"
            if let loginConfig = initParams.loginConfig?.values.first,
               let savedDappShare = KeychainManager.shared.getDappShare(verifier: loginConfig.verifier) {
                loginParams.dappShare = savedDappShare
            }
            
            let sdkUrlParams = SetUpMFAParams(options: initParams, params: loginParams, actionType: "enable_mfa", sessionId: sessionId ?? "")
            
            let loginId = try await getLoginId(data: sdkUrlParams)
            
            let jsonObject: [String: String?] = [
                "loginId": loginId
            ]
            
            let url = try Web3Auth.generateAuthSessionURL(initParams: initParams, jsonObject: jsonObject, isWalletServices: false)
            
            return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Bool, Error>) in
                
                authSession = ASWebAuthenticationSession(
                    url: url, callbackURLScheme: redirectURL.scheme) { callbackURL, authError in
                        
                        guard
                            authError == nil,
                            let callbackURL = callbackURL,
                            let sessionId = try? Web3Auth.decodeSessionStringfromCallbackURL(callbackURL)
                        else {
                            let authError = authError ?? Web3AuthError.unknownError
                            if case ASWebAuthenticationSessionError.canceledLogin = authError {
                                continuation.resume(throwing: Web3AuthError.userCancelled)
                            } else {
                                continuation.resume(throwing: authError)
                            }
                            return
                        }
                        
                        self.sessionManager.setSessionID(sessionId)
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
    
    public func launchWalletServices(_ loginParams: W3ALoginParams) async throws {
        
        let sessionId = self.sessionManager.getSessionID()
        if !(sessionId ?? "").isEmpty {
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let redirectURL = URL(string: "\(bundleId)://auth")
            else { throw Web3AuthError.noBundleIdentifierFound }
            var loginParams = loginParams
            //assign loginParams redirectUrl from intiParamas redirectUrl
            loginParams.redirectUrl = "\(bundleId)://auth"
            if let loginConfig = initParams.loginConfig?.values.first,
               let savedDappShare = KeychainManager.shared.getDappShare(verifier: loginConfig.verifier) {
                loginParams.dappShare = savedDappShare
            }
            
            let sdkUrlParams = SdkUrlParams(options: initParams, params: loginParams, actionType: "login")
            let _sessionId = sessionManager.getSessionID() ?? ""
            let loginId = try await getLoginId(data: sdkUrlParams)
            self.sessionManager.setSessionID(_sessionId)
    
            let jsonObject: [String: String?] = [
                "loginId": loginId,
                "sessionId": sessionId
            ]

            let url = try Web3Auth.generateAuthSessionURL(initParams: initParams, jsonObject: jsonObject, isWalletServices: true)
            //open url in webview
            await UIApplication.shared.keyWindow?.rootViewController?.present(webViewController, animated: true, completion: nil)
            await webViewController.webView.load(URLRequest(url: url))
        }
        else {
            throw Web3AuthError.runtimeError("SessionId not found. Please login first.")
        }
    }

    static func generateAuthSessionURL(initParams: W3AInitParams, jsonObject: [String: String?], isWalletServices: Bool) throws -> URL {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting.insert(.sortedKeys)

        guard
            let data = try? jsonEncoder.encode(jsonObject),
            // Using sorted keys to produce consistent results
            var components = isWalletServices ?
                URLComponents(string: initParams.walletSdkUrl!.absoluteString) :
                URLComponents(string: initParams.sdkUrl!.absoluteString)
        else {
            throw Web3AuthError.encodingError
        }

        components.path = isWalletServices ? "/wallet" : "/start"
        components.fragment = "b64Params=" + data.toBase64URL()

        guard let url = components.url
        else {
            throw Web3AuthError.runtimeError("Invalid URL")
        }

        return url
    }

    static func decodeStateFromCallbackURL(_ callbackURL: URL) throws -> Web3AuthState {
        guard
            let callbackFragment = callbackURL.fragment,
            let callbackData = Data.fromBase64URL(callbackFragment),
            let callbackState = try? JSONDecoder().decode(Web3AuthState.self, from: callbackData)

        else {
            throw Web3AuthError.decodingError
        }
        return callbackState
    }
    
    static func decodeSessionStringfromCallbackURL(_ callbackURL: URL) throws -> String? {
        let callbackFragment = callbackURL.fragment
        return callbackFragment?.components(separatedBy: "&")[0].components(separatedBy: "=")[1]
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
}

extension Web3Auth: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
