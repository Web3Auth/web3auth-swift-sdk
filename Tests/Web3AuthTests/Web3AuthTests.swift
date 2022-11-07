@testable import Web3Auth
import XCTest

class Web3AuthTests: XCTestCase {
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
        XCTAssertEqual(name, decodedState?.userInfo?.name)
        XCTAssertEqual(profileImage, decodedState?.userInfo?.profileImage)
        XCTAssertEqual(typeOfLogin, decodedState?.userInfo?.typeOfLogin)
    }
}
