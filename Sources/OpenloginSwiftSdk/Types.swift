import Foundation

public enum Network : String {
    case mainnet = "mainnet"
    case testnet = "testnet"
    case development = "development"
}

public enum Method : String {
    case login = "/login"
    case logout = "/logout"
}
