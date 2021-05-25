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
    <string>{mainnet|testnet}</string>
 </dict>
 </plist>
 ```

 - parameter bundle: Bundle to locate the file `OpenLogin.plist`. Default is the main bundle.

 - returns: OpenLogin WebAuth component.
 - important: Calling this method without a valid file `OpenLogin.plist` in your bundle will crash your application.
 */
public func webAuth(bundle: Bundle = Bundle.main) -> WebAuthenticatable {
    let values = plistValues(bundle: bundle)!
    return webAuth(clientId: values.clientId, network: values.network)
}

/**
 OpenLogin component for authenticating with web-based flow.

 ```
 OpenLogin.webAuth(clientId: clientId, network: .mainnet)
 ```

 - parameter clientId: Your OpenLogin project ID.
 - parameter network:  Network to run OpenLogin.

 - returns: OpenLogin WebAuth component.
 */
public func webAuth(clientId: String, network: Network) -> WebAuthenticatable {
    return WebAuth(clientId: clientId, network: network)
}

/// WebAuth authentication using OpenLogin.
public protocol WebAuthenticatable {
    var clientId: String { get }
    var network: Network { get }

    /**
     Starts the WebAuth flow by modally presenting a ViewController in the top-most controller.

     ```
     OpenLogin
         .webAuth()
         .start {
             switch $0 {
             case .success(let credentials):
                 signedIn(credentials)
             case .failure(let error):
                 print("Error: \(error)")
             }
         }
     ```

     Then you just need to resume the WebAuh session from `AppDelegate`:

     ```
     func application(app: UIApplication, openURL url: NSURL, options: [String : Any]) -> Bool {
         return OpenLogin.resumeAuth(url)
     }
     ```
     
     Or `App` if you're using SwiftUI lifecycle:
     
     ```
     var body: some Scene {
         WindowGroup {
             ContentView()
                .onOpenURL { url in
                    OpenLogin.resumeAuth(url)
                }
         }
     }
     ```

     Any ongoing WebAuth session will be automatically cancelled when starting a new one,
     and its corresponding callback with be called with a failure result of `OpenLogin.WebAuthError.cancelled`.

     - parameter callback: Callback called with the result of the WebAuth flow.
     */
    func start(_ callback: @escaping (Result<Credentials>) -> Void)

    /**
     Logs out and clears current OpenLogin session.

     ```
     OpenLogin
         .webAuth()
         .clearSession {
            signedOut()
        }
     ```

     - parameter callback: Callback called with bool outcome of the call.
     */
    func clearSession(callback: @escaping (Bool) -> Void)
}
