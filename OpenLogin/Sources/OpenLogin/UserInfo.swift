import Foundation

public struct UserInfo: Decodable {
    public let name: String
    public let profileImage: String?
    public let typeOfLogin: String
}
