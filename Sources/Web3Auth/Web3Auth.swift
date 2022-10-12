
import AuthenticationServices
import OSLog

/**
 Authentication using Web3Auth.
 */

public class Web3Auth: NSObject {
    private let initParams: W3AInitParams
    /// You can check the state variable before logging the user in, if the user has an active session the state variable will already have all the values you get from login so the user does not have to re-login
    public var state: Web3AuthState?
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
        super.init()
        await checkForSession()
    }

    func checkForSession() async {
        if let sessionID = KeychainManager.shared.get(key: .sessionID) {
            Task {
                do {
                    state = try await SessionManagement.shared.getActiveSession(sessionID: sessionID)
                } catch let error {
                    os_log("%s", log: getTorusLogger(log: Web3AuthLogger.core, type: .error), type: .error, error.localizedDescription)
                }
            }
        }
    }

    public func logout() async throws {
        if let sessionID = KeychainManager.shared.get(key: .sessionID) {
            try await SessionManagement.shared.logout(sessionID: sessionID)
        }
        KeychainManager.shared.delete(key: .sessionID)
        if let state = state, let verifer = state.userInfo?.verifier, let dappShare = KeychainManager.shared.getDappShare(verifier: verifer) {
            KeychainManager.shared.delete(key: .custom(dappShare))
        }
        state = nil
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
    public func login(_ loginParams: W3ALoginParams, _ callback: @escaping (Result<Web3AuthState>) -> Void) {
        DispatchQueue.main.async { [self] in
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let redirectURL = URL(string: "\(bundleId)://auth")
            else { return callback(.failure(Web3AuthError.noBundleIdentifierFound)) }
            var loginParams = loginParams
            if let loginConfig = initParams.loginConfig?.values.first, let savedDappShare = KeychainManager.shared.getDappShare(verifier: loginConfig.verifier) {
                loginParams.dappShare = savedDappShare
            }
            guard
                let url = try? Web3Auth.generateAuthSessionURL(redirectURL: redirectURL, initParams: initParams, loginParams: loginParams)

            else {
                return callback(.failure(Web3AuthError.unknownError))
            }

            let authSession = ASWebAuthenticationSession(
                url: url, callbackURLScheme: redirectURL.scheme) { callbackURL, authError in

                    guard
                        authError == nil,
                        let callbackURL = callbackURL,
                        let callbackState = try? Web3Auth.decodeStateFromCallbackURL(callbackURL)
                    else {
                        let authError = authError ?? Web3AuthError.unknownError
                        if case ASWebAuthenticationSessionError.canceledLogin = authError {
                            return callback(.failure(Web3AuthError.userCancelled))
                        } else {
                            return callback(.failure(authError))
                        }
                    }
                    if let safeUserInfo = callbackState.userInfo {
                        KeychainManager.shared.saveDappShare(userInfo: safeUserInfo)
                    }
                    KeychainManager.shared.save(key: .sessionID, val: callbackState.sessionId ?? "")
                    self.state = callbackState
                    callback(.success(callbackState))
                }

            authSession.presentationContextProvider = self

            if !authSession.start() {
                callback(.failure(Web3AuthError.unknownError))
            }
        }
    }

    static func generateAuthSessionURL(redirectURL: URL, initParams: W3AInitParams, loginParams: W3ALoginParams) throws -> URL {
        var overridenInitParams = initParams

        // Init params redirectUrl has to be overriden unless users have their own tricks
        if overridenInitParams.redirectUrl == nil {
            overridenInitParams.redirectUrl = redirectURL.absoluteString
        }

        let sdkUrlParams = SdkUrlParams(initParams: overridenInitParams, params: loginParams)

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting.insert(.sortedKeys)

        guard
            let data = try? jsonEncoder.encode(sdkUrlParams),
            // Using sorted keys to produce consistent results
            var components = URLComponents(string: initParams.sdkUrl.absoluteString)
        else {
            throw Web3AuthError.unknownError
        }

        components.path = "/login"
        components.fragment = data.toBase64URL()

        guard let url = components.url
        else {
            throw Web3AuthError.unknownError
        }

        return url
    }

    static func decodeStateFromCallbackURL(_ callbackURL: URL) throws -> Web3AuthState {
        guard
            let callbackFragment = callbackURL.fragment,
            let callbackData = Data.fromBase64URL(callbackFragment),
            let callbackState = try? JSONDecoder().decode(Web3AuthState.self, from: callbackData)
        else {
            throw Web3AuthError.unknownError
        }
        return callbackState
    }
}

extension Web3Auth: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
