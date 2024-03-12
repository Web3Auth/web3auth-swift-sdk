import Foundation

public struct SignResponse: Codable {
    let success: Bool
    let result: String
    let error: String
}
