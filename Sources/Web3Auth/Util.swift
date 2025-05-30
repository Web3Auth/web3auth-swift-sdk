import Foundation
import FetchNodeDetails

func plistValues(_ bundle: Bundle) -> (clientId: String, web3AuthNetwork: Web3AuthNetwork, redirectUrl: String)? {
    guard
        let path = bundle.path(forResource: "Web3Auth", ofType: "plist"),
        let values = NSDictionary(contentsOfFile: path) as? [String: Any]
    else {
        print("Missing Web3Auth.plist file in your bundle!")
        return nil
    }

    guard
        let clientId = values["ClientId"] as? String,
        let networkValue = values["Network"] as? String,
        let redirectUrl = values["RedirectUrl"] as? String,
        let web3AuthNetwork = Web3AuthNetwork(string: networkValue)
    else {
        print("Web3Auth.plist file at \(path) is missing or having incorrect 'ClientId' and/or 'Network' entries!")
        print("File currently has the following entries: \(values)")
        return nil
    }
    return (clientId: clientId, web3AuthNetwork: web3AuthNetwork, redirectUrl)
}

extension WhiteLabelData {
    func merge(with other: WhiteLabelData) -> WhiteLabelData {
        return WhiteLabelData(
            appName: appName ?? other.appName,
            logoLight: logoLight ?? other.logoLight,
            logoDark: logoDark ?? other.logoDark,
            defaultLanguage: defaultLanguage ?? other.defaultLanguage,
            mode: mode ?? other.mode,
            theme: theme ?? other.theme,
            appUrl: appUrl ?? other.appUrl,
            useLogoLoader: useLogoLoader ?? other.useLogoLoader
        )
    }
}
