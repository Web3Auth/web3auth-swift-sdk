import Foundation

func plistValues(_ bundle: Bundle) -> (clientId: String, network: Network)? {
    guard
        let path = bundle.path(forResource: "OpenLogin", ofType: "plist"),
        let values = NSDictionary(contentsOfFile: path) as? [String: Any]
    else {
        print("Missing OpenLogin.plist file in your bundle!")
        return nil
    }
    
    guard
        let clientId = values["ClientId"] as? String,
        let networkValue = values["Network"] as? String,
        let network = Network(rawValue: networkValue)
    else {
        print("OpenLogin.plist file at \(path) is missing or having incorrect 'ClientId' and/or 'Network' entries!")
        print("File currently has the following entries: \(values)")
        return nil
    }
    return (clientId: clientId, network: network)
}

func decodedBase64(_ base64URLSafe: String) -> Data? {
    var base64 = base64URLSafe
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    if base64.count % 4 != 0 {
        base64.append(String(repeating: "=", count: 4 - base64.count % 4))
    }
    return Data(base64Encoded: base64)
}
