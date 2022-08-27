import CryptoKit
import CryptoSwift
import Foundation
import secp256k1
@testable import Web3Auth
import XCTest

@available(iOS 12.0, *)
class Web3AuthTests: XCTestCase {
    func testEncryptAndSign() {
        let privKey = "dda863b615ac6de27fb680b5563db3c19176a6f42cc1dee1768e220983385e3e"
        let encdata = "{\"iv\":\"693407372626b11017d0ec30acd29e6a\",\"ciphertext\":\"cbe09442851a0463b3e34e2f912c6aee\",\"ephemPublicKey\":\"0477e20c5d9e3281a4eca7d07c1c4cc9765522ea7966cd7ea8f552da42049778d4fcf44b35b59e84eddb1fa3266350e4f2d69d62da82819d51f107550e03852661\",\"mac\":\"96d358f46ef371982af600829c101e78f6c5d5f960bd96fdd2ca52763ee50f65\"}"
        let sig = SECP256K1().sign(privkey: privKey, messageData: encdata)
        XCTAssertEqual(sig, "3045022100b0161b8abbd66da28734d105e28455bf9a48a33ee1dfde71f96e2e919717565002204d53303ec05596ca6784cff1d25eb0e764f70ff5e1ce16a896ec58255b25b5ff")
    }

    func testGenerateAuthSessionURL() throws {
        let redirectURL = URL(string: "com.web3auth.sdkapp://web3auth")!
        let initParams = W3AInitParams(clientId: "BC01p_js5KUIjvqYYAzWlDKt6ft--5joV0TbZEKO7YbDTqnmU5v0sq_4wgkyh0QAfZZAi-v6nKD4kcxkAqPuj8U", network: .testnet)
        let loginParams = W3ALoginParams(loginProvider: .APPLE)
        let correctGeneratedURL = "https://sdk.openlogin.com/login#eyJpbml0Ijp7ImNsaWVudElkIjoiQkMwMXBfanM1S1VJanZxWVlBeldsREt0NmZ0LS01am9WMFRiWkVLTzdZYkRUcW5tVTV2MHNxXzR3Z2t5aDBRQWZaWkFpLXY2bktENGtjeGtBcVB1ajhVIiwibmV0d29yayI6InRlc3RuZXQiLCJyZWRpcmVjdFVybCI6ImNvbS53ZWIzYXV0aC5zZGthcHA6XC9cL3dlYjNhdXRoIiwic2RrVXJsIjoiaHR0cHM6XC9cL3Nkay5vcGVubG9naW4uY29tIn0sInBhcmFtcyI6eyJsb2dpblByb3ZpZGVyIjoiYXBwbGUifX0"

        XCTAssertEqual(try? Web3Auth.generateAuthSessionURL(redirectURL: redirectURL, initParams: initParams, loginParams: loginParams), URL(string: correctGeneratedURL)!)
    }

    func testDecodeStateFromCallbackURL() throws {
        let callbackURL = "com.web3auth.sdkapp://web3auth/#eyJwcml2S2V5IjoiMmE2MDhiMGQzNjc0ODZmOTI4ZjFkZmJlNjRmYjM3MzYxNjQ0OTU4NDZkY2Y3NmNmNzgwOGNiOWE0NDZlZTViNyIsInVzZXJJbmZvIjp7ImVtYWlsIjoianJma2l1ZnJqckBwcml2YXRlcmVsYXkuYXBwbGVpZC5jb20iLCJuYW1lIjoiSm9obiBUYWthIiwicHJvZmlsZUltYWdlIjoiaHR0cHM6Ly9pMC53cC5jb20vY2RuLmF1dGgwLmNvbS9hdmF0YXJzL2p0LnBuZyIsImFnZ3JlZ2F0ZVZlcmlmaWVyIjoidGtleS1hdXRoMC1hcHBsZSIsInZlcmlmaWVyIjoidG9ydXMiLCJ2ZXJpZmllcklkIjoiYXBwbGV8MDAxNTU5LmVjYmViMjgwMzZjMDcwZmQzMjU1YTViODM3ZWU3ZmJjLjA0NTQiLCJ0eXBlT2ZMb2dpbiI6ImFwcGxlIn19"

        let privKey = "2a608b0d367486f928f1dfbe64fb3736164495846dcf76cf7808cb9a446ee5b7"
        let name = "John Taka"
        let profileImage = "https://i0.wp.com/cdn.auth0.com/avatars/jt.png"
        let typeOfLogin = "apple"

        let decodedState = try? Web3Auth.decodeStateFromCallbackURL(URL(string: callbackURL)!)

        XCTAssertEqual(privKey, decodedState?.privKey)
        XCTAssertEqual(name, decodedState?.userInfo.name)
        XCTAssertEqual(profileImage, decodedState?.userInfo.profileImage)
        XCTAssertEqual(typeOfLogin, decodedState?.userInfo.typeOfLogin)
    }
}
