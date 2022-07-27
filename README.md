# web3auth-swift-sdk

Web3Auth SDK for iOS applications.

## Requirements

- iOS 13+
- Xcode 11+
- Swift 4.x / 5.x

## Installation

If you are using the Swift Package Manager, open the following menu item in Xcode:

**File > Swift Packages > Add Package Dependency...**

In the Choose Package Repository prompt add this url:

```
https://github.com/web3auth/web3auth-swift-sdk
```

If you are using cocoapods , open the pod file and add 

```
pod 'Web3Auth', '3.4.0'
```

then do a pod install and you are good to go.


## Getting Started

Authentication with In-App Web-based Flow (iOS 12+):

1. Import **Web3Auth** into your project.

```swift
import Web3Auth
```

2. Present the In-App Web-based Login modal. The user should see a permission dialog.

```
Web3Auth()
    .login(OLInitParams(loginProvider: .GOOGLE)) {
        switch $0 {
        case .success(let result):
            print("""
                Signed in successfully!
                    Private key: \(result.privKey)
                    ed25519PrivKey : \(result.ed25519PrivKey)
                    Session ID : \(result.sessionId)
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

## Configuration

In order to use Web3Auth you need to provide your Web3Auth **ClientId** and which **Network** to run it.

- Go to [Web3Auth Developer Dashboard](https://dashboard.web3auth.io), create or open an existing Web3Auth project and copy your Client ID, which is the **ClientId**.

- You can now create an instance of the Web3Auth class using the above clientid and Network of your choice
```
   Web3Auth(W3AInitParams(clientId: "your-client-id",network: .mainnet))
   
```
-If you want to use Whitelabel or Custom Authentication, you will also have to specify it in the dynamic paramter constructor as well.

Please also whitelist `\(bundleId)://auth` in the developer dashboard. This step is mandatory for the redirect to work.

## Next steps

See example app in [Web3authSwiftSdkDemo](/Web3authSwiftSdkDemo)

Checkout our Integration Builder for IOS on our website (https://web3auth.io/docs/integration-builder)
