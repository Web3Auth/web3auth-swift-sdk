import Foundation

public enum BuildEnv: String, Codable {
    case production
    case staging
    case testing
}

/// Disambiguates from `FetchNodeDetails.BuildEnv` for apps that import both modules.
public typealias Web3AuthBuildEnv = BuildEnv
