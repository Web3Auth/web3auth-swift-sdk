@testable import Web3Auth
import XCTest
import curveSecp256k1

@available(iOS 13.0, *)

class Web3AuthTests: XCTestCase {
    func testPadLeft() {
        let str = "abc"
        XCTAssertEqual(str.padStart(toLength: 10), "       abc")
        XCTAssertEqual(str.padStart(toLength: 10, padString: "foo"), "foofoofabc")
        XCTAssertEqual(str.padStart(toLength: 6, padString: "123456"), "123abc")
        XCTAssertEqual(str.padStart(toLength: 8, padString: "0"), "00000abc")
        XCTAssertEqual(str.padStart(toLength: 1), "abc")
    }

    func testSign() throws {
        let privKey = "bce6550a433b2e38067501222f9e75a2d4c5a433a6d27ec90cd81fbd4194cc2b"
        let encData = try keccak256(data: "test data".data(using: .utf8)!)
        do {
            let sig = try curveSecp256k1.ECDSA.signRecoverable(key: SecretKey(hex: privKey), hash: encData.hexString)
            let serialized = try sig.serialize()
            XCTAssertEqual(String(serialized.prefix(64)), "d7736799107d8e6308af995d827dc8772993cd8ccab5c230fe8277cecb02f31a")
            XCTAssertEqual(String(serialized.suffix(66).prefix(64)), "4df631a4059f45d8cb0e8889ff1b8096243796189ec00440883b1c0271a19e80")
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testEncryptAndSign() throws {
        let privKey = "dda863b615ac6de27fb680b5563db3c19176a6f42cc1dee1768e220983385e3e"
        let encdata = "{\"iv\":\"693407372626b11017d0ec30acd29e6a\",\"ciphertext\":\"cbe09442851a0463b3e34e2f912c6aee\",\"ephemPublicKey\":\"0477e20c5d9e3281a4eca7d07c1c4cc9765522ea7966cd7ea8f552da42049778d4fcf44b35b59e84eddb1fa3266350e4f2d69d62da82819d51f107550e03852661\",\"mac\":\"96d358f46ef371982af600829c101e78f6c5d5f960bd96fdd2ca52763ee50f65\"}"
        let encData = try keccak256(data: encdata.data(using: .utf8)!)
        do {
            let sig = try curveSecp256k1.ECDSA.signRecoverable(key: SecretKey(hex: privKey), hash: encData.hexString)
            let serialized = try sig.serialize()
            XCTAssertEqual(String(serialized.prefix(64)), "b0161b8abbd66da28734d105e28455bf9a48a33ee1dfde71f96e2e9197175650")
            XCTAssertEqual(String(serialized.suffix(66).prefix(64)), "4d53303ec05596ca6784cff1d25eb0e764f70ff5e1ce16a896ec58255b25b5ff")
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecodeStateFromCallbackURL() throws {
        let callbackURL = "com.web3auth.sdkapp://auth/#eyJwcml2S2V5IjoiMGJhZGRmZmU2YjYzZDRlZjNiZWJmNjVkZWUzNjA0YThhZWY3MDJkNmJjOWNiM2NhYjcwODQ0YWYzOGU5ZjZlNCIsInNlc3Npb25JZCI6IjU0ODllYmRhNjkyMmU2NzUwY2MyYWZkOTc3MzJlM2ExZWE0NWE3MjU4MjdhODBiZjA5YzA0NGY4MWQzMjM0NWQiLCJlZDI1NTE5UHJpdktleSI6IjBiYWRkZmZlNmI2M2Q0ZWYzYmViZjY1ZGVlMzYwNGE4YWVmNzAyZDZiYzljYjNjYWI3MDg0NGFmMzhlOWY2ZTRiMTM1YmRiMGY5ODg4ZjQ1MTc5OTBiNzAyYmFiNGQ0YmYxNTNkOGUzMTRiZTQxYWM3ZDY5MmU2ZDAyODBkMjcxIiwidXNlckluZm8iOnsiZW1haWwiOiJkaHJ1dkB0b3IudXMiLCJuYW1lIjoiRGhydXYgSmFpc3dhbCIsInByb2ZpbGVJbWFnZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FMbTV3dTJlRUZyZWh4dzVUaFhlV3plTDNycEF0aTZUR3hOUEFYRlRGdmxSPXM5Ni1jIiwiYWdncmVnYXRlVmVyaWZpZXIiOiJ0a2V5LWdvb2dsZS1scmMiLCJ2ZXJpZmllciI6InRvcnVzIiwidmVyaWZpZXJJZCI6ImRocnV2QHRvci51cyIsInR5cGVPZkxvZ2luIjoiZ29vZ2xlIiwiZGFwcFNoYXJlIjoiIiwiaWRUb2tlbiI6ImV5SmhiR2NpT2lKRlV6STFOaUlzSW5SNWNDSTZJa3BYVkNJc0ltdHBaQ0k2SWxSWlQyZG5YeTAxUlU5RllteGhXUzFXVmxKWmNWWmhSRUZuY0hSdVprdFdORFV6TlUxYVVFTXdkekFpZlEuZXlKcFlYUWlPakUyTmpRNU5ETTBOalVzSW1GMVpDSTZJa0pLV1VseVNIVjZiSFZEYkVKTE1IWjJWRUpWU2pkclVYbHNWbDlFYWpOT1FTMVlNWEUwVVhaNGN6SkJlVE5FZVZOcllXTlBjRzlQWWpnemJFUlVTRXBTVmxrNE0ySkdiRmwwZERSd09IQlJVaTF2UTFsMGR5SXNJbTV2Ym1ObElqb2lNREpqWkRjeFpUWmlOVFJrTVRVeU5tTXdOMlkwTXpRMFl6WTNaV1V6TmpNMlpXVXpOVEEzTURrd01tSTVOR1V3TkdZellUTTNObVZrTnpSaE1tTXlNR1l6SWl3aWFYTnpJam9pYUhSMGNITTZMeTloY0drdWIzQmxibXh2WjJsdUxtTnZiU0lzSW5kaGJHeGxkSE1pT2x0N0luQjFZbXhwWTE5clpYa2lPaUl3TXpsbFpXWmxaR1ExTUdaa09HUXdOamRrTmpBME5EVTBNRFZtWW1KbVpXTXdOall5TkRBME4yWTNNV1l6T0dFek9UY3dNRFUyTlRnMlkyUm1OVFZoWVRRaUxDSjBlWEJsSWpvaWQyVmlNMkYxZEdoZllYQndYMnRsZVNJc0ltTjFjblpsSWpvaWMyVmpjREkxTm1zeEluMWRMQ0psYldGcGJDSTZJbVJvY25WMlFIUnZjaTUxY3lJc0ltNWhiV1VpT2lKRWFISjFkaUJLWVdsemQyRnNJaXdpY0hKdlptbHNaVWx0WVdkbElqb2lhSFIwY0hNNkx5OXNhRE11WjI5dloyeGxkWE5sY21OdmJuUmxiblF1WTI5dEwyRXZRVXh0TlhkMU1tVkZSbkpsYUhoM05WUm9XR1ZYZW1WTU0zSndRWFJwTmxSSGVFNVFRVmhHVkVaMmJGSTljemsyTFdNaUxDSjJaWEpwWm1sbGNpSTZJblJ2Y25Weklpd2lkbVZ5YVdacFpYSkpaQ0k2SW1Sb2NuVjJRSFJ2Y2k1MWN5SXNJbUZuWjNKbFoyRjBaVlpsY21sbWFXVnlJam9pZEd0bGVTMW5iMjluYkdVdGJISmpJaXdpWlhod0lqb3hOalkxTURJNU9EWTFmUS5tVGF1VGpPdjB0Vm90R1NzVUhFbmFVYTMxQnNZS1RhUHdueG9sR3gzdVRZZ1pmaEl2WWRFTVliNVBPMnRkanEyMUNlQkhTMDdYMmlxNVZaNTJ3TFY2dyIsIm9BdXRoSWRUb2tlbiI6IiJ9fQ"

        // let privKey = "0baddffe6b63d4ef3bebf65dee3604a8aef702d6bc9cb3cab70844af38e9f6e4"
        // let name = "Dhruv Jaiswal"
        // let email = "dhruv@tor.us"
        // let typeOfLogin = "google"

        let decodedState = try Web3Auth.decodeStateFromCallbackURL(URL(string: callbackURL)!)
        
        //XCTAssertEqual(privKey, decodedState.privKey)
        //XCTAssertEqual(name, decodedState.userInfo?.name)
        //XCTAssertEqual(email, decodedState.userInfo?.email)
        //XCTAssertEqual(typeOfLogin, decodedState.userInfo?.typeOfLogin)
    }
}
