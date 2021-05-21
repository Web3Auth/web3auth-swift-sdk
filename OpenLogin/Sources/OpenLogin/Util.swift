import Foundation

protocol JSONObjectPayload {
    init?(json: [String: Any])
}

func plistValues(bundle: Bundle) -> (clientId: String, network: Network)? {
    guard
        let path = bundle.path(forResource: "OpenLogin", ofType: "plist"),
        let values = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            print("Missing OpenLogin.plist file with 'ClientId' and 'Network' entries in main bundle!")
            return nil
        }

    guard
        let clientId = values["ClientId"] as? String,
        let network = values["Network"] as? String,
        let network = Network(rawValue: network)
        else {
            print("OpenLogin.plist file at \(path) is missing 'ClientId' and/or 'Network' entries!")
            print("File currently has the following entries: \(values)")
            return nil
        }
    return (clientId: clientId, network: network)
}
