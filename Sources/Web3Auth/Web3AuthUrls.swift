import Foundation

/// URL maps aligned with `@toruslabs/constants` (`CITADEL_SERVER_MAP`,
/// `STORAGE_SERVER_MAP`, `DASHBOARD_PUBLIC_API_MAP`, `STORAGE_SERVER_SOCKET_URL_MAP`).
public enum Web3AuthUrls {
    public static func citadelServerUrl(_ buildEnv: BuildEnv?) -> String {
        switch buildEnv {
        case .testing:
            return "https://api-develop.web3auth.io/citadel-service"
        default:
            return "https://api.web3auth.io/citadel-service"
        }
    }

    public static func storageServerUrl(_ buildEnv: BuildEnv?) -> String {
        switch buildEnv {
        case .testing:
            return "https://api-develop.web3auth.io/session-service"
        default:
            return "https://api.web3auth.io/session-service"
        }
    }

    public static func sessionSocketUrl(_ buildEnv: BuildEnv?) -> String {
        switch buildEnv {
        case .testing:
            return "https://develop-session.web3auth.io"
        default:
            return "https://session.web3auth.io"
        }
    }

    public static func dashboardPublicApiUrl(_ buildEnv: BuildEnv?) -> String {
        switch buildEnv {
        case .testing:
            return "https://api-develop.web3auth.io/signer-service"
        default:
            return "https://api.web3auth.io/signer-service"
        }
    }
}

public let LOGIN_SOURCE_IOS = "web3auth-ios"
public let LOGIN_SOURCE_FLUTTER = "web3auth-flutter"
public let DEFAULT_SESSION_TIME = 30 * 86400
public let authServiceVersion = "v11"
public let walletServicesVersion = "v6"
public let authDashboardVersion = "v11"
public let walletAccountConstant = "wallet/account"
