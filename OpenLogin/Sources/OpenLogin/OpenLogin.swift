import Foundation

/**
 OpenLogin component for authenticating with web-based flow.
 
 ```
 OpenLogin.webAuth()
 ```
 
 Parameters are loaded from the file `OpenLogin.plist` in your bundle with the following content:
 
 ```
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
     <dict>
         <key>ClientId</key>
         <string>{YOUR_CLIENT_ID}</string>
         <key>Network</key>
         <string>mainnet|testnet</string>
     </dict>
 </plist>
 ```
 
 - parameter bundle: Bundle to locate the `OpenLogin.plist` file. By default is the main bundle.
 
 - returns: OpenLogin WebAuth component.
 - important: Calling this method without a valid `OpenLogin.plist` will crash your application.
 */
@available(iOS 12.0, *)
public func webAuth(_ bundle: Bundle = Bundle.main) -> WebAuth {
    let values = plistValues(bundle)!
    return webAuth(clientId: values.clientId, network: values.network)
}

/**
 OpenLogin  component for authenticating with web-based flow.

 ```
 OpenLogin.webAuth(clientId: clientId, network: .mainnet)
 ```

 - parameter clientId: Id of your OpenLogin project.
 - parameter domain:   Network to run OpenLogin.

 - returns: OpenLogin WebAuth component.
 */
@available(iOS 12.0, *)
public func webAuth(clientId: String, network: Network) -> WebAuth {
    return WebAuth(clientId: clientId, network: network)
}

public func resumeAuth(_ url: URL) {
    print("OpenLogin.resumeAuth: \(url)")
}
