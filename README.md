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

- iOS 14
- Xcode 12.x+
- Swift 5.x


## ⚡ Installation
### SPM
If you are using the Swift Package Manager, open the following menu item in Xcode:

**File > Swift Packages > Add Package Dependency...**

In the Choose Package Repository prompt add this url:

```
https://github.com/web3auth/web3auth-swift-sdk
```

### Cocoapods
If you are using cocoapods , open the pod file and add 

```
pod 'Web3Auth', '9.0.0'
```

## 🌟 Configuration

Checkout [SDK Reference](https://web3auth.io/docs/sdk/pnp/ios/install#configure-redirection) to configure the iOS App.

## Getting State
```swift
import Web3Auth

let web3auth = try Web3Auth(W3AInitParams(
  // Get your Web3Auth Client Id from dashboard.web3auth.io
  clientId: "YOUR_WEB3AUTH_CLIENT_ID",
  network: .sapphire_mainnet,
  redirectUrl: "bundleId://auth"
))

// Login
let result = try await web3Auth.login(W3ALoginParams(loginProvider: .GOOGLE))

// Logout
try await web3auth.logout()
```

## 🩹 Examples

Checkout the examples for your preferred blockchain and platform in our [examples](https://github.com/Web3Auth/web3auth-pnp-examples/tree/main/ios)

## 🌐 Demo

Checkout the [Web3Auth Demo](https://demo-app.web3auth.io/) to see how Web3Auth can be used in an application.

Have a look at our [Web3Auth PnP iOS Quick Start](https://github.com/Web3Auth/web3auth-pnp-examples/tree/main/ios/ios-quick-start) to help you quickly integrate a basic instance of Web3Auth Plug and Play in your iOS app.

Further checkout the [demo folder](https://github.com/Web3Auth/web3auth-swift-sdk/tree/master/Web3authSwiftSdkDemo) within this repository, which contains a sample app.

## 💬 Troubleshooting and Support

- Have a look at our [Community Portal](https://community.web3auth.io/) to see if anyone has any questions or issues you might be having. Feel free to create new topics and we'll help you out as soon as possible.
- Checkout our [Troubleshooting Documentation Page](https://web3auth.io/docs/troubleshooting) to know the common issues and solutions.
- For Priority Support, please have a look at our [Pricing Page](https://web3auth.io/pricing.html) for the plan that suits your needs.
