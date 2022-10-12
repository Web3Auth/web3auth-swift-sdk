@testable import Web3Auth
import XCTest

@available(iOS 13.0, *)
class Web3AuthTests: XCTestCase {
    func testEncryptAndSign() {
        let privKey = "dda863b615ac6de27fb680b5563db3c19176a6f42cc1dee1768e220983385e3e"
        let encdata = "{\"iv\":\"693407372626b11017d0ec30acd29e6a\",\"ciphertext\":\"cbe09442851a0463b3e34e2f912c6aee\",\"ephemPublicKey\":\"0477e20c5d9e3281a4eca7d07c1c4cc9765522ea7966cd7ea8f552da42049778d4fcf44b35b59e84eddb1fa3266350e4f2d69d62da82819d51f107550e03852661\",\"mac\":\"96d358f46ef371982af600829c101e78f6c5d5f960bd96fdd2ca52763ee50f65\"}"
        let sig = try? SECP256K1().sign(privkey: privKey, messageData: encdata)
        XCTAssertEqual(sig, "3045022100b0161b8abbd66da28734d105e28455bf9a48a33ee1dfde71f96e2e919717565002204d53303ec05596ca6784cff1d25eb0e764f70ff5e1ce16a896ec58255b25b5ff")
    }

    func testGenerateAuthSessionURL() throws {
        let redirectURL = URL(string: "com.web3auth.sdkapp://auth")!
        let initParams = W3AInitParams(clientId: "BJYIrHuzluClBK0vvTBUJ7kQylV_Dj3NA-X1q4Qvxs2Ay3DySkacOpoOb83lDTHJRVY83bFlYtt4p8pQR-oCYtw", network: .testnet)
        let loginParams = W3ALoginParams(loginProvider: .GOOGLE)
        let correctGeneratedURL = "https://sdk.openlogin.com/login#eyJpbml0Ijp7ImNsaWVudElkIjoiQkpZSXJIdXpsdUNsQkswdnZUQlVKN2tReWxWX0RqM05BLVgxcTRRdnhzMkF5M0R5U2thY09wb09iODNsRFRISlJWWTgzYkZsWXR0NHA4cFFSLW9DWXR3IiwibmV0d29yayI6InRlc3RuZXQiLCJyZWRpcmVjdFVybCI6ImNvbS53ZWIzYXV0aC5zZGthcHA6XC9cL2F1dGgiLCJzZGtVcmwiOiJodHRwczpcL1wvc2RrLm9wZW5sb2dpbi5jb20ifSwicGFyYW1zIjp7ImN1cnZlIjoic2VjcDI1NmsxIiwibG9naW5Qcm92aWRlciI6Imdvb2dsZSIsInNlc3Npb25UaW1lIjo4NjQwMH19"

        XCTAssertEqual(try? Web3Auth.generateAuthSessionURL(redirectURL: redirectURL, initParams: initParams, loginParams: loginParams), URL(string: correctGeneratedURL)!)
    }

    func testDecodeStateFromCallbackURL() throws {
        let callbackURL = "com.web3auth.sdkapp://auth/#eyJwcml2S2V5IjoiMGJhZGRmZmU2YjYzZDRlZjNiZWJmNjVkZWUzNjA0YThhZWY3MDJkNmJjOWNiM2NhYjcwODQ0YWYzOGU5ZjZlNCIsInNlc3Npb25JZCI6IjU0ODllYmRhNjkyMmU2NzUwY2MyYWZkOTc3MzJlM2ExZWE0NWE3MjU4MjdhODBiZjA5YzA0NGY4MWQzMjM0NWQiLCJlZDI1NTE5UHJpdktleSI6IjBiYWRkZmZlNmI2M2Q0ZWYzYmViZjY1ZGVlMzYwNGE4YWVmNzAyZDZiYzljYjNjYWI3MDg0NGFmMzhlOWY2ZTRiMTM1YmRiMGY5ODg4ZjQ1MTc5OTBiNzAyYmFiNGQ0YmYxNTNkOGUzMTRiZTQxYWM3ZDY5MmU2ZDAyODBkMjcxIiwidXNlckluZm8iOnsiZW1haWwiOiJkaHJ1dkB0b3IudXMiLCJuYW1lIjoiRGhydXYgSmFpc3dhbCIsInByb2ZpbGVJbWFnZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FMbTV3dTJlRUZyZWh4dzVUaFhlV3plTDNycEF0aTZUR3hOUEFYRlRGdmxSPXM5Ni1jIiwiYWdncmVnYXRlVmVyaWZpZXIiOiJ0a2V5LWdvb2dsZS1scmMiLCJ2ZXJpZmllciI6InRvcnVzIiwidmVyaWZpZXJJZCI6ImRocnV2QHRvci51cyIsInR5cGVPZkxvZ2luIjoiZ29vZ2xlIiwiZGFwcFNoYXJlIjoiIiwiaWRUb2tlbiI6ImV5SmhiR2NpT2lKRlV6STFOaUlzSW5SNWNDSTZJa3BYVkNJc0ltdHBaQ0k2SWxSWlQyZG5YeTAxUlU5RllteGhXUzFXVmxKWmNWWmhSRUZuY0hSdVprdFdORFV6TlUxYVVFTXdkekFpZlEuZXlKcFlYUWlPakUyTmpRNU5ETTBOalVzSW1GMVpDSTZJa0pLV1VseVNIVjZiSFZEYkVKTE1IWjJWRUpWU2pkclVYbHNWbDlFYWpOT1FTMVlNWEUwVVhaNGN6SkJlVE5FZVZOcllXTlBjRzlQWWpnemJFUlVTRXBTVmxrNE0ySkdiRmwwZERSd09IQlJVaTF2UTFsMGR5SXNJbTV2Ym1ObElqb2lNREpqWkRjeFpUWmlOVFJrTVRVeU5tTXdOMlkwTXpRMFl6WTNaV1V6TmpNMlpXVXpOVEEzTURrd01tSTVOR1V3TkdZellUTTNObVZrTnpSaE1tTXlNR1l6SWl3aWFYTnpJam9pYUhSMGNITTZMeTloY0drdWIzQmxibXh2WjJsdUxtTnZiU0lzSW5kaGJHeGxkSE1pT2x0N0luQjFZbXhwWTE5clpYa2lPaUl3TXpsbFpXWmxaR1ExTUdaa09HUXdOamRrTmpBME5EVTBNRFZtWW1KbVpXTXdOall5TkRBME4yWTNNV1l6T0dFek9UY3dNRFUyTlRnMlkyUm1OVFZoWVRRaUxDSjBlWEJsSWpvaWQyVmlNMkYxZEdoZllYQndYMnRsZVNJc0ltTjFjblpsSWpvaWMyVmpjREkxTm1zeEluMWRMQ0psYldGcGJDSTZJbVJvY25WMlFIUnZjaTUxY3lJc0ltNWhiV1VpT2lKRWFISjFkaUJLWVdsemQyRnNJaXdpY0hKdlptbHNaVWx0WVdkbElqb2lhSFIwY0hNNkx5OXNhRE11WjI5dloyeGxkWE5sY21OdmJuUmxiblF1WTI5dEwyRXZRVXh0TlhkMU1tVkZSbkpsYUhoM05WUm9XR1ZYZW1WTU0zSndRWFJwTmxSSGVFNVFRVmhHVkVaMmJGSTljemsyTFdNaUxDSjJaWEpwWm1sbGNpSTZJblJ2Y25Weklpd2lkbVZ5YVdacFpYSkpaQ0k2SW1Sb2NuVjJRSFJ2Y2k1MWN5SXNJbUZuWjNKbFoyRjBaVlpsY21sbWFXVnlJam9pZEd0bGVTMW5iMjluYkdVdGJISmpJaXdpWlhod0lqb3hOalkxTURJNU9EWTFmUS5tVGF1VGpPdjB0Vm90R1NzVUhFbmFVYTMxQnNZS1RhUHdueG9sR3gzdVRZZ1pmaEl2WWRFTVliNVBPMnRkanEyMUNlQkhTMDdYMmlxNVZaNTJ3TFY2dyIsIm9BdXRoSWRUb2tlbiI6IiJ9fQ"

        let privKey = "0baddffe6b63d4ef3bebf65dee3604a8aef702d6bc9cb3cab70844af38e9f6e4"
        let name = "Dhruv Jaiswal"
        let email = "dhruv@tor.us"
        let typeOfLogin = "google"

        let decodedState = try? Web3Auth.decodeStateFromCallbackURL(URL(string: callbackURL)!)

        XCTAssertEqual(privKey, decodedState?.privKey)
        XCTAssertEqual(name, decodedState?.userInfo?.name)
        XCTAssertEqual(email, decodedState?.userInfo?.email)
        XCTAssertEqual(typeOfLogin, decodedState?.userInfo?.typeOfLogin)
    }
}
