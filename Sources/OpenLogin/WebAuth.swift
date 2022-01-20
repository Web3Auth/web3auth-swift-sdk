import UIKit
import AuthenticationServices
import SafariServices

public struct OLInitParams {
    public init(clientId: String, network: Network, sdkURL: URL? = nil) {
        self.clientId = clientId
        self.network = network
        if let sdkURL = sdkURL {
            self.sdkURL = sdkURL
        }
    }
    
    public init(clientId: String, network: Network) {
        self.clientId = clientId
        self.network = network
    }
    
    let clientId: String
    let network: Network
    var sdkURL: URL = URL(string: "https://sdk.openlogin.com")!
}

public struct OLLoginParams {
    public init(provider: OpenLoginProvider? = nil, relogin: Bool? = nil, skipTKey: Bool? = nil, extraLoginOptions: Dictionary<String, Any>? = nil, redirectURL: String? = nil, appState: String? = nil) {
        self.provider = provider
        self.relogin = relogin
        self.skipTKey = skipTKey
        self.extraLoginOptions = extraLoginOptions
        self.redirectURL = redirectURL
        self.appState = appState
    }
     
    public init(provider: OpenLoginProvider? = nil) {
        self.provider = provider
        self.relogin = nil
        self.skipTKey = nil
        self.extraLoginOptions = nil
        self.redirectURL = nil
        self.appState = nil
    }
    
    let provider: OpenLoginProvider?
    let relogin: Bool?
    let skipTKey: Bool?
    let extraLoginOptions: Dictionary<String, Any>?
    let redirectURL: String?
    let appState: String?
}

/**
 WebAuth Authentication using OpenLogin.
 */
@available(iOS 12.0, *)
public class WebAuth: NSObject {
    
    private let initParams: OLInitParams
    
    public init(_ params: OLInitParams) {
        self.initParams = params
    }
    
    /**
     Starts the WebAuth flow by modally presenting a ViewController in the top-most controller.

     ```
     OpenLogin
         .webAuth()
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
     and it's corresponding callback with be called with a failure result of `WebAuthError.appCancelled`

     - parameter callback: Callback called with the result of the WebAuth flow.
     */
    public func login(_ loginParams: OLLoginParams, _ callback: @escaping (Result<OpenLoginState>) -> Void) {
        DispatchQueue.main.async { [self] in
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let redirectURL = URL(string: "\(bundleId)://openlogin")
            else { return callback(.failure(WebAuthError.noBundleIdentifierFound)) }
            
            guard
                let url = try? WebAuth.generateAuthSessionURL(redirectURL: redirectURL, initParams: initParams, loginParams: loginParams)
            else {
                return callback(.failure(WebAuthError.unknownError))
            }
            
            let authSession = ASWebAuthenticationSession(
                url: url, callbackURLScheme: redirectURL.scheme) { callbackURL, authError in
                guard
                    authError == nil,
                    let callbackURL = callbackURL,
                    let callbackState = try? WebAuth.decodeStateFromCallbackURL(callbackURL)
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
    
    static func generateAuthSessionURL(redirectURL: URL, initParams: OLInitParams, loginParams: OLLoginParams) throws -> URL {
        
        var sdkParams: Dictionary<String, Any> = [:]
        
        if let provider = loginParams.provider {
            sdkParams["loginProvider"] = "\(provider)".lowercased()
        }
        
        if let relogin = loginParams.relogin {
            sdkParams["relogin"] = relogin
        }
        
        if let skipTKey = loginParams.skipTKey {
            sdkParams["skipTKey"] = skipTKey
        }
        
        if let extraLoginOptions = loginParams.extraLoginOptions {
            sdkParams["extraLoginOptions"] = extraLoginOptions
        }
        
        if let sdkSwiftURL = loginParams.redirectURL {
            sdkParams["redirectUrl"] = sdkSwiftURL
        }
        
        if let appState = loginParams.appState {
            sdkParams["appState"] = appState
        }
        
        let params: [String: Any] = [
            "init": [
                "clientId": initParams.clientId,
                "network": initParams.network.rawValue,
                "redirectUrl": redirectURL.absoluteString
            ],
            "params": sdkParams
        ]
        
        guard
            let data = try? JSONSerialization.data(withJSONObject: params, options: [.sortedKeys]),
            // Using sorted keys to produce consistent results
            var components = URLComponents(string: initParams.sdkURL.absoluteString)
        else {
            throw WebAuthError.unknownError
        }
        
        components.path = "/login"
        components.fragment = data.base64EncodedString()
        
        guard let url = components.url
        else {
            throw WebAuthError.unknownError
        }
        
        return url
    }
    
    static func decodeStateFromCallbackURL(_ callbackURL: URL) throws -> OpenLoginState {
        guard
            let callbackFragment = callbackURL.fragment,
            let callbackData = decodedBase64(callbackFragment),
            let callbackState = try? JSONDecoder().decode(OpenLoginState.self, from: callbackData)
        else {
            throw WebAuthError.unknownError
        }
        return callbackState
    }
    
}

@available(iOS 12.0, *)
extension WebAuth: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
