import Foundation

@available(iOS 12.0, *)
public func webAuth(_ bundle: Bundle = Bundle.main) -> WebAuth {
    let values = plistValues(bundle)!
    return webAuth(clientId: values.clientId, network: values.network)
}

@available(iOS 12.0, *)
public func webAuth(clientId: String, network: Network) -> WebAuth {
    return WebAuth(clientId: clientId, network: network)
}

public func resumeAuth(_ url: URL) {
    print("OpenLogin.resumeAuth: \(url)")
}
