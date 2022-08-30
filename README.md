# web3auth-swift-sdk

Web3Auth SDK for iOS applications.

## Requirements

- iOS 13+
- Xcode 11.4+ / 12.x
- Swift 4.x / 5.x

## Installation

If you are using the Swift Package Manager, open the following menu item in Xcode:

**File > Swift Packages > Add Package Dependency...**

In the Choose Package Repository prompt add this url:

```
https://github.com/web3auth/web3auth-swift-sdk
```

## Getting Started

Authentication with In-App Web-based Flow (iOS 13+):

1. Import **Web3Auth** into your project.

```swift
import Web3Auth
```

2. Present the In-App Web-based Login modal. The user should see a permission dialog.

```
 Task{
       await Web3Auth()
    .login(OLInitParams(loginProvider: .GOOGLE)) {
        switch $0 {
        case .success(let result):
            print("""
                Signed in successfully!
                    Private key: \(result.privKey)
                    User info:
                        Name: \(result.userInfo.name)
                        Profile image: \(result.userInfo.profileImage ?? "N/A")
                        Type of login: \(result.userInfo.typeOfLogin)
                """)
        case .failure(let error):
            print("Error: \(error)")
        }
    }
    }
```

## Configuration

In order to use Web3Auth you need to provide your Web3Auth **ClientId** and which **Network** to run it.

- Go to [Web3Auth Developer Dashboard](https://dashboard.web3auth.io), create or open an existing Web3Auth project and copy your Client ID, which is the **ClientId**.

- Set the clientID and network in the Web3Auth initializer

```
Task {
 await Web3Auth(W3AInitParams(clientId: "BJYIrHuzluClBK0vvTBUJ7kQylV_Dj3NA-X1q4Qvxs2Ay3DySkacOpoOb83lDTHJRVY83bFlYtt4p8pQR-oCYtw", network: .testnet)
}
```

Please also whitelist `\(bundleId)://auth` in the developer dashboard. This step is mandatory for the redirect to work.

## Next steps

See example app in [Web3authSwiftSdkDemo](/Web3authSwiftSdkDemo)
