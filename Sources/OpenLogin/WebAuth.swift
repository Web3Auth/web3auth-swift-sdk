import UIKit
import AuthenticationServices
import SafariServices

public struct OLInitParams {
    let clientId: String
    let network: Network
    let sdkURL: URL = URL(string: "https://sdk.openlogin.com")!
}

public struct OLLoginParams {
    let provider: OpenLoginProvider?
    let fastLogin: Bool?
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
    
    public init(params: OLInitParams) {
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
    public func login(loginParams: OLLoginParams, _ callback: @escaping (Result<OpenLoginState>) -> Void) {
        DispatchQueue.main.async { [self] in
            guard
                let bundleId = Bundle.main.bundleIdentifier,
                let redirectURL = URL(string: "\(bundleId)://openlogin")
            else { return callback(.failure(WebAuthError.noBundleIdentifierFound)) }
            
            var sdkParams: Dictionary<String, Any> = [:]
            
            if let provider = loginParams.provider {
                sdkParams["loginProvider"] = "\(provider)".lowercased()
            }
            
            if let fastLogin = loginParams.fastLogin {
                sdkParams["fastLogin"] = fastLogin
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
                let data = try? JSONSerialization.data(withJSONObject: params),
                var components = URLComponents(string: initParams.sdkURL.absoluteString)
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
                    let callbackState = try? JSONDecoder().decode(OpenLoginState.self, from: callbackData)
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
