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

        let publicKeyHex = SECP256K1.privateToPublic(privateKey: privKey.web3.hexData!, compressed: false)!.web3.hexString.web3.noHexPrefix
        XCTAssertEqual(publicKeyHex, "0491d075b1dc46db8c0769d508d0c771f7ca5d3c8346d7aab99fad04b0f14b92d21fb6ab148cb84dcc4c886b8baee36925e9497b0893964219d2c82a9152a36301")
        //let encdata = try! SessionManagement.shared.encryptData(privkeyHex: privKey, d: "")
        let encdata = "{\"iv\":\"693407372626b11017d0ec30acd29e6a\",\"ciphertext\":\"cbe09442851a0463b3e34e2f912c6aee\",\"ephemPublicKey\":\"0477e20c5d9e3281a4eca7d07c1c4cc9765522ea7966cd7ea8f552da42049778d4fcf44b35b59e84eddb1fa3266350e4f2d69d62da82819d51f107550e03852661\",\"mac\":\"96d358f46ef371982af600829c101e78f6c5d5f960bd96fdd2ca52763ee50f65\"}"
        let sig = SECP256K1().sign(privkey: privKey, messageData: encdata)
       // print(encdata.sha3(.keccak256))
        XCTAssertEqual(sig, "3045022100b0161b8abbd66da28734d105e28455bf9a48a33ee1dfde71f96e2e919717565002204d53303ec05596ca6784cff1d25eb0e764f70ff5e1ce16a896ec58255b25b5ff")
        
    }

    
    
    
    
    
    func testSign() {
        let privKey =
            "dda863b615ac6de27fb680b5563db3c19176a6f42cc1dee1768e220983385e3e"
        let msg = "{\"iv\":\"e784fb3cccc2bb626fcf6e6d212c5ccf\",\"ephemPublicKey\":\"043590eee6b16781aedb68b6b5ed842ee32160a10d9732b1e6996c9337b5c0f68a4e1a1507470c911dfc59ed7361bba8ae7f0c7c6c8e2840c4dcc0e46d916edfa0\",\"ciphertext\":\"645cd0852b48c1b99d1388a0e5c51e69\",\"mac\":\"cba322146b69b6dd0f3451b521c5dade17b4966a9a7583a31a93169bd2d91a47\"}"
        msg.web3.keccak256
        let hash = SHA3(variant: .keccak256).calculate(for: [UInt8](hex: msg)).toHexString()
        let hash2 = msg.sha3(.keccak256)
        // print(hash == hash2)
        let sig = SECP256K1().sign(privkey: privKey, messageData: hash)
        XCTAssertEqual(sig, "3044022065e644f71f66356692238de78a70acfb3ce359d8c77cd59eaeb6b0eaf34017fb022006d10d5cec4a03d9a0014ac1cad4fe7751dd1f8f769282206b14569022152ad8")
    }

    func testSignShortMsg() {
        var encData = "{\"iv\":\"0ed4e648bda65ce0b8b75dbf900b3416\",\"ciphertext\":\"5d9a6a40a555974a6eaa36353546c521\",\"ephemPublicKey\":\"0406202038aeaced55bdba0d2670ec554cba3b7e7f0641719216236244af15985114cc14c9d28943d8cd6d6b1d6b82c68b2853faa3077a51229a9ecf26d97cacb5\",\"mac\":\"08d06b6da17b77f44c49b4edf4a6e064792bf16efba8d07b23d0734683912231\"}"
        // print(SHA3(variant: .keccak256).calculate(for: Array<UInt8>(encData.data(using: .utf8)!)).toHexString())
        print(encData.sha3(.keccak256))
        let privkey: [UInt8] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let sig = SECP256K1().sign(privkey: privkey.hexa, messageData: encData)
        XCTAssertEqual(sig, "30440220069fc6694da08960e2f14c007376df1dd0dcfc788c21f4f203368259c302227b022036ce1253c20f538531e64f365c33bbde64dfb8982b81cabca86119a2ad2465ea")
    }

    func testEncrypt() {
        let arr: [UInt8] = [4, 77, 75, 108, 209, 54, 16, 50, 202, 155, 210, 174, 185, 217, 0, 170, 77, 69, 217, 234, 216, 10, 201, 66, 51, 116, 196, 81, 167, 37, 77, 7, 102, 42, 62, 173, 162, 208, 254, 32, 139, 109, 37, 124, 235, 15, 6, 66, 132, 102, 46, 133, 127, 87, 182, 107, 84, 193, 152, 189, 49, 13, 237, 54, 208]
        let key = arr.toHexString()
        try? SessionManagement.shared.encrypt(publicKey: key, msg: "to a", opts: nil)
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




