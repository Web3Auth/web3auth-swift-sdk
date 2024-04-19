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
        let callbackURL = "com.web3auth.sdkapp://auth/#b64Params=eyJzZXNzaW9uSWQiOiI2NTRjMmFlZDRkOTA0ZmQ3Y2Q1MGVkYWUzOWMxNWUxMzgxMDcxNWJkNTUzZWEwM2Y1MmZiZWQ1Y2Q5ZDE3ZmQ5In0"

        let decodedState = try? Web3Auth.decodeStateFromCallbackURL(URL(string: callbackURL)!)

        let sessionId = "654c2aed4d904fd7cd50edae39c15e13810715bd553ea03f52fbed5cd9d17fd9"
        XCTAssertEqual(sessionId, decodedState?.sessionId)
    }
}
