# Web3Auth iOS SDK

Web3Auth is where passwordless auth meets non-custodial key infrastructure for Web3 apps and wallets. By aggregating OAuth (Google, Twitter, Discord) logins, different wallets and innovative Multi Party Computation (MPC) - Web3Auth provides a seamless login experience to every user on your application.

## 📖 Documentation

Checkout the official [Web3Auth Documentation](https://web3auth.io/docs) and [SDK Reference](https://web3auth.io/docs/sdk/ios/) to get started!

## 💡 Features
- Plug and Play, OAuth based Web3 Authentication Service
- Fully decentralized, non-custodial key infrastructure
- End to end Whitelabelable solution
- Threshold Cryptography based Key Reconstruction
- Multi Factor Authentication Setup & Recovery (Includes password, backup phrase, device factor editing/deletion etc)
- Support for WebAuthn & Passwordless Login
- Support for connecting to multiple wallets
- DApp Active Session Management

...and a lot more

## ⏪ Requirements

- iOS 13+
- Xcode 11+
- Swift 4.x / 5.x

## ⚡ Installation

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

### Getting Started

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

## 🌟 Configuration

In order to use Web3Auth you need to provide your Web3Auth **ClientId** and which **Network** to run it.

- Go to [Web3Auth Developer Dashboard](https://dashboard.web3auth.io), create or open an existing Web3Auth project and copy your Client ID, which is the **ClientId**.

- You can now create an instance of the Web3Auth class using the above clientid and Network of your choice
```
   Web3Auth(W3AInitParams(clientId: "your-client-id",network: .mainnet))
   
```
-If you want to use Whitelabel or Custom Authentication, you will also have to specify it in the dynamic paramter constructor as well.

Please also whitelist `\(bundleId)://auth` in the developer dashboard. This step is mandatory for the redirect to work.

## 🩹 Examples

Checkout the examples for your preferred blockchain and platform in our [examples repository](https://github.com/Web3Auth/examples/)

## 🌐 Demo

Checkout the [Web3Auth Demo](https://demo-app.web3auth.io/) to see how Web3Auth can be used in an application.

Further checkout the [demo folder](https://github.com/Web3Auth/web3auth-swift-sdk/tree/master/Web3authSwiftSdkDemo) within this repository, which contains a sample app.

## 💬 Troubleshooting and Discussions

- Have a look at our [GitHub Discussions](https://github.com/Web3Auth/Web3Auth/discussions?discussions_q=sort%3Atop) to see if anyone has any questions or issues you might be having.
- Checkout our [Troubleshooting Documentation Page](https://web3auth.io/docs/troubleshooting) to know the common issues and solutions
- Join our [Discord](https://discord.gg/web3auth) to join our community and get private integration support or help with your integration.
