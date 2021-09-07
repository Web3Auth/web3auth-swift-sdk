import UIKit
import AuthenticationServices
import SafariServices

/**
 WebAuth Authentication using OpenLogin.
 */
@available(iOS 12.0, *)
public class WebAuth: NSObject {
    static let sdkURL = URL(string: "https://sdk.openlogin.com")!
    
    let configFastLoginKey = "TORUS_OPENLOGIN_USE_FASTLOGIN"
    
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
         .start {
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
    public func start(_ callback: @escaping (Result<State>) -> Void) {
        guard
            let bundleId = Bundle.main.bundleIdentifier,
            let redirectURL = URL(string: "\(bundleId)://openlogin")
        else { return callback(.failure(WebAuthError.noBundleIdentifierFound)) }
        
        // Get the current config of fastLogin, defaults to false
        let fastLogin = UserDefaults.standard.bool(forKey: configFastLoginKey)
        
        // Enable fastLogin for subsequent logins
        UserDefaults.standard.set(true, forKey: configFastLoginKey)
        
        let params: [String: Any] = [
            "init": [
                "clientId": clientId,
                "network": network.rawValue,
                "redirectUrl": redirectURL.absoluteString
            ],
            "params": [
                "fastLogin": fastLogin

            ]
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
    
    /**
     Sign the user out. This methods does not actually sign the user out from the server-side. Instead, it disables fastLogin in the next login actions.
     */
    public func signOut(){
        // Disable fastLogin for subsequent logins
        UserDefaults.standard.set(false, forKey: configFastLoginKey)
    }
    
}

@available(iOS 12.0, *)
extension WebAuth: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
