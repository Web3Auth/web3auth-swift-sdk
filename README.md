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
- Xcode 11.4+ / 12.x
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
pod 'Web3Auth', '5.0.0'
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

3. You can check the state variable before logging the user in, if the user has an active session the state variable will already have all the values you get from login so the user does not have to re-login
```
Task{
let web3auth = await Web3Auth()
let state = web3auth.state
}

```

## 🌟 Configuration

In order to use Web3Auth you need to provide your Web3Auth **ClientId** and which **Network** to run it.

- Go to [Web3Auth Developer Dashboard](https://dashboard.web3auth.io), create or open an existing Web3Auth project and copy your Client ID, which is the **ClientId**.

- Set the clientID and network in the Web3Auth initializer

```
Task {
 await Web3Auth(W3AInitParams(clientId: "BJYIrHuzluClBK0vvTBUJ7kQylV_Dj3NA-X1q4Qvxs2Ay3DySkacOpoOb83lDTHJRVY83bFlYtt4p8pQR-oCYtw", network: .testnet)
}
```

Please also whitelist `\(bundleId)://auth` in the developer dashboard. This step is mandatory for the redirect to work.

## 🩹 Examples

Checkout the examples for your preferred blockchain and platform in our [examples](https://web3auth.io/docs/examples)

## 🌐 Demo

Checkout the [Web3Auth Demo](https://demo-app.web3auth.io/) to see how Web3Auth can be used in an application.

Further checkout the [demo folder](https://github.com/Web3Auth/web3auth-swift-sdk/tree/master/Web3authSwiftSdkDemo) within this repository, which contains a sample app.

## 💬 Troubleshooting and Support

- Have a look at our [Community Portal](https://community.web3auth.io/) to see if anyone has any questions or issues you might be having. Feel free to create new topics and we'll help you out as soon as possible.
- Checkout our [Troubleshooting Documentation Page](https://web3auth.io/docs/troubleshooting) to know the common issues and solutions.
- For Priority Support, please have a look at our [Pricing Page](https://web3auth.io/pricing.html) for the plan that suits your needs.
