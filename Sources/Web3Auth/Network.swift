import Foundation

/**
 List of networks that can run Web3Auth.
 */
public enum Web3AuthNetwork: String, Codable {
    case mainnet
    case testnet
    case cyan
    case aqua
    case celeste
    case sapphire_devnet
    case sapphire_mainnet
}
