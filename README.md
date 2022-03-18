# web3auth-swift-sdk

Torus Web3Auth SDK for iOS applications.

## Requirements

- iOS 12+
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

- Go to [Torus Developer](https://developer.tor.us), create or open an existing Web3Auth project and copy your project ID, which is the **ClientId**.

In your application bundle add a plist file named **Web3Auth.plist** with the following information:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>ClientId</key>
  <string>YOUR_OPENLOGIN_CLIENT_ID</string>
  <key>Network</key>
  <string>mainnet | testnet</string>
</dict>
</plist>
```

## Next steps

See example app in [Web3authSwiftSdkDemo](/Web3authSwiftSdkDemo)
