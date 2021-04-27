import XCTest
@testable import OpenloginSwiftSdk

final class OpenloginSwiftSdkTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(OpenloginSwiftSdk().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
