//
//  DerTest.swift
//
//
//  Created by Dhruv Jaiswal on 11/10/22.
//

@testable import Web3Auth
import XCTest

final class DerTest: XCTestCase {
    func test1() {
        let privKey = "dda863b615ac6de27fb680b5563db3c19176a6f42cc1dee1768e220983385e3e"
        let encData = "{\"iv\":\"693407372626b11017d0ec30acd29e6a\",\"ciphertext\":\"cbe09442851a0463b3e34e2f912c6aee\",\"ephemPublicKey\":\"0477e20c5d9e3281a4eca7d07c1c4cc9765522ea7966cd7ea8f552da42049778d4fcf44b35b59e84eddb1fa3266350e4f2d69d62da82819d51f107550e03852661\",\"mac\":\"96d358f46ef371982af600829c101e78f6c5d5f960bd96fdd2ca52763ee50f65\"}"
        let data = encData.data(using: .utf8)!

        let sig = SECP256K1.signForRecovery(hash: data.sha3(.keccak256), privateKey: privKey.hexa.data)
        let der = try? SECP256K1.toDERReepresentaion(sig: sig.rawSignature?.data ?? Data())
        XCTAssertEqual(der, "3045022100b0161b8abbd66da28734d105e28455bf9a48a33ee1dfde71f96e2e919717565002204d53303ec05596ca6784cff1d25eb0e764f70ff5e1ce16a896ec58255b25b5ff")
    }

    func test2() {
        let privKey = "5489ebda6922e6750cc2afd97732e3a1ea45a725827a80bf09c044f81d32345d"
        let encData = "{\"iv\":\"62d16f98178a71d5a266064d9d111591\",\"ciphertext\":\"29a74a07fd45e8c303e20054e58eda34\",\"ephemPublicKey\":\"041fdee3a18854220014f34834dac5b440bac706b558d05f62ceace6877fc515126200aa39ac4f922d5a8ab6da4d948f45f1f0aae37aa2fade2cd0a15b36a3ed04\",\"mac\":\"34b73b33b08c54cf48ca85072f7f57bc89b2835926d70ec6e347460f84debb02\"}"

        let data = encData.data(using: .utf8)!

        let sig = SECP256K1.signForRecovery(hash: data.sha3(.keccak256), privateKey: privKey.hexa.data)
        let der = try? SECP256K1.toDERReepresentaion(sig: sig.rawSignature?.data ?? Data())
        XCTAssertEqual(der, "3044022071d7f85cc0f0f1351318b2304922b65c3ee965cf642cadba2f268f3a1f859ce202200ee6e7486118197bb958a0d5fca7d7001a3b35a03eb3f19c8cb7d77efd55e09c")
    }
}
