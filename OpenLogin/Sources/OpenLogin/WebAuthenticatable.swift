import Foundation

/**
 OpenLogin component for authenticating with web-based flow.

 ```
 OpenLogin.webAuth()
 ```

 Parameters are loaded from `OpenLogin.plist` in your bundle with the following content:

 ```
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
    <key>ClientId</key>
    <string>{YOUR_CLIENT_ID}</string>
    <key>Network</key>
    <string>{mainnet|testnet}</string>
 </dict>
 </plist>
 ```

 - parameter bundle: Bundle used to locate `OpenLogin.plist`. Default is the main bundle.

 - returns: OpenLogin WebAuth component.
 - important: Calling this method without a valid `OpenLogin.plist` will crash your application.
 */
public func webAuth(bundle: Bundle = Bundle.main) -> WebAuthenticatable {
    let values = plistValues(bundle: bundle)!
    return webAuth(clientId: values.clientId, network: values.network)
}

/**
 OpenLogin  component for authenticating with web-based flow.

 ```
 OpenLogin.webAuth(clientId: clientId, network: "mainnet")
 ```

 - parameter clientId: Your OpenLogin project ID.
 - parameter network:  Network to run OpenLogin, either  "mainnet" or "testnet".

 - returns: OpenLogin WebAuth component.
 */
public func webAuth(clientId: String, network: Network) -> WebAuthenticatable {
    return WebAuth(clientId: clientId, network: network)
}

/// WebAuth Authentication using OpenLogin.
public protocol WebAuthenticatable {
    var clientId: String { get }
    var network: Network { get }

    /**
     For redirect url instead of a custom scheme it will use `https` and Universal Links.

     Before enabling this flag you'll need to configure Universal Links

     - returns: the same WebAuth instance to allow method chaining
     */
    func useUniversalLink() -> Self

    /// Specify a redirect url to be used instead of a custom scheme
    ///
    /// - Parameter redirectURL: custom redirect url
    /// - Returns: the same WebAuth instance to allow method chaining
    func redirectURL(_ redirectURL: URL) -> Self

    #if swift(>=5.1)
    /**
     Disable Single Sign On (SSO) on iOS 13+ and macOS.
     Has no effect on older versions of iOS.

     - returns: the same WebAuth instance to allow method chaining
     */
    func useEphemeralSession() -> Self
    #endif

    /**
     Starts the WebAuth flow by modally presenting a ViewController in the top-most controller.

     ```
     OpenLogin
         .webAuth(clientId: clientId, network: "mainnet")
         .start { result in
             print(result)
         }
     ```

     Then from `AppDelegate` we just need to resume the WebAuth Auth like this

     ```
     func application(app: UIApplication, openURL url: NSURL, options: [String : Any]) -> Bool {
         return OpenLogin.resumeAuth(url, options: options)
     }
     ```

     Any on going WebAuth Auth session will be automatically cancelled when starting a new one,
     and it's corresponding callback with be called with a failure result of `Authentication.Error.Cancelled`

     - parameter callback: callback called with the result of the WebAuth flow
     */
    func start(_ callback: @escaping (Result<Credentials>) -> Void)

    /**
     Logs out and removes OpenLogin session
     
     For iOS 11+ you will need to ensure that the **Callback URL** has been added
     to the **Whitelist URLs** section of your application in the [OpenLogin Project](https://developer.tor.us).

     ```
     OpenLogin
         .webAuth()
         .clearSession { print($0) }
     ```

     - parameter callback: callback called with bool outcome of the call
     */
    func clearSession(callback: @escaping (Bool) -> Void)
}
