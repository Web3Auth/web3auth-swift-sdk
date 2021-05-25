import UIKit
import AuthenticationServices

@available(iOS 12.0, *)
public class WebAuth: NSObject {
    static let sdkURL = URL(string: "https://sdk.openlogin.com")!
    
    private let clientId: String
    private let network: Network
    
    public init(clientId: String, network: Network) {
        self.clientId = clientId
        self.network = network
    }
    
    public func start(_ callback: @escaping (Result<State>) -> Void) {
        guard
            let bundleId = Bundle.main.bundleIdentifier,
            let redirectURL = URL(string: "\(bundleId)://openlogin")
        else { return callback(.failure(WebAuthError.noBundleIdentifierFound)) }
        
        let params: [String: Any] = [
            "init": [
                "clientId": clientId,
                "network": network.rawValue,
                "redirectUrl": redirectURL.absoluteString
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
}

@available(iOS 12.0, *)
extension WebAuth: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
