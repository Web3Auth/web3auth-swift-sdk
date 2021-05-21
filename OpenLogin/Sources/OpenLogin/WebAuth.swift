import Foundation

import AuthenticationServices

class WebAuth: WebAuthenticatable {
    let clientId: String
    let network: Network
    
    private lazy var redirectURL: URL? = {
        guard
            let bundleIdentifier = Bundle.main.bundleIdentifier,
            let url = URL(string: "https://sdk.openlogin.com"),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else { return nil }
        return components.url
    }()

    init(clientId: String, network: Network) {
        self.clientId = clientId
        self.network = network
    }
    
    func redirectURL(_ redirectURL: URL) -> Self {
        self.redirectURL = redirectURL
        return self
    }
    
    func start(_ callback: @escaping (Result<Credentials>) -> Void) {
        guard let redirectURL = redirectURL else { return callback(.failure(WebAuthError.noBundleIdentifierFound)) }
        guard let url = buildStartURL(redirectURL: redirectURL) else { return callback(.failure(WebAuthError.unknown)) }
        
        print("Going to \(url)")
        print("Redirecting to \(redirectURL)")
        callback(.success(Credentials(privKey: "<private key>")))
    }
    
    func clearSession(callback: @escaping (Bool) -> Void) {
        callback(true)
    }
    
    func buildStartURL(redirectURL: URL) -> URL? {
        let params: [String: Any] = [
            "init": [
                "clientId": clientId,
                "network": network.rawValue,
                "redirectUrl": "http://localhost"
            ]
        ]
        
        guard let paramsData = try? JSONSerialization.data(withJSONObject: params) else { return nil }
        
        guard var components = URLComponents(string: "https://sdk.openlogin.com/login") else { return nil }
        components.fragment = paramsData.base64EncodedString()
        
        return components.url
    }
}
