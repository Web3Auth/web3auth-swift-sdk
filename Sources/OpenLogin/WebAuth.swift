import UIKit
import AuthenticationServices
import SafariServices

/**
 WebAuth Authentication using OpenLogin.
 */
@available(iOS 12.0, *)
public class WebAuth: NSObject {
    static let sdkURL = URL(string: "https://sdk.openlogin.com")!
    
    private let clientId: String
    private let network: Network
    
    public init(clientId: String, network: Network) {
        self.clientId = clientId
        self.network = network
    }
    
    /**
     Starts the WebAuth flow by modally presenting a ViewController in the top-most controller.

     ```
     OpenLogin
         .webAuth()
         .login {
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
     and it's corresponding callback with be called with a failure result of `WebAuthError.appCancelled`

     - parameter callback: Callback called with the result of the WebAuth flow.
     */
    public func login(provider: OpenLoginProvider? = nil, fastLogin: Bool? = nil, relogin: Bool? = nil, skipTKey: Bool? = nil, extraLoginOptions: Dictionary<String, Any>? = nil, redirectURL sdkSwiftURL: String? = nil, appState: String? = nil, _ callback: @escaping (Result<State>) -> Void) {
        DispatchQueue.main.async { [self] in
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let redirectURL = URL(string: "\(bundleId)://openlogin")
            else { return callback(.failure(WebAuthError.noBundleIdentifierFound)) }
            
            var sdkParams: Dictionary<String, Any> = [:]
            
            if let provider = provider {
                sdkParams["loginProvider"] = "\(provider)".lowercased()
            }
            
            if let fastLogin = fastLogin {
                sdkParams["fastLogin"] = fastLogin
            }
            
            if let relogin = relogin {
                sdkParams["relogin"] = relogin
            }
            
            if let skipTKey = skipTKey {
                sdkParams["skipTKey"] = skipTKey
            }
            
            if let extraLoginOptions = extraLoginOptions {
                sdkParams["extraLoginOptions"] = extraLoginOptions
            }
            
            if let sdkSwiftURL = sdkSwiftURL {
                sdkParams["redirectUrl"] = sdkSwiftURL
            }
            
            if let appState = appState {
                sdkParams["appState"] = appState
            }
            
            
            
            let params: [String: Any] = [
                "init": [
                    "clientId": clientId,
                    "network": network.rawValue,
                    "redirectUrl": redirectURL.absoluteString
                ],
                "params": sdkParams
            ]
                    
            guard
                let data = try? JSONSerialization.data(withJSONObject: params),
                var components = URLComponents(string: WebAuth.sdkURL.absoluteString)
            else { return callback(.failure(WebAuthError.unknownError)) }
            
            components.path = "/login"
            components.fragment = data.base64EncodedString()
            
            guard let url = components.url
            else { return callback(.failure(WebAuthError.unknownError)) }
            
            let authSession = ASWebAuthenticationSession(
                url: url, callbackURLScheme: redirectURL.scheme) { callbackURL, authError in
                guard
                    authError == nil,
                    let callbackURL = callbackURL,
                    let callbackFragment = callbackURL.fragment,
                    let callbackData = decodedBase64(callbackFragment),
                    let callbackState = try? JSONDecoder().decode(State.self, from: callbackData)
                else {
                    let authError = authError ?? WebAuthError.unknownError
                    if case ASWebAuthenticationSessionError.canceledLogin = authError {
                        return callback(.failure(WebAuthError.userCancelled))
                    } else {
                        return callback(.failure(authError))
                    }
                }
                callback(.success(callbackState))
            }
            
            if #available(iOS 13.0, *) {
                authSession.presentationContextProvider = self
            }
            
            if !authSession.start() {
                callback(.failure(WebAuthError.unknownError))
            }
        }
    }
    
}

@available(iOS 12.0, *)
extension WebAuth: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
