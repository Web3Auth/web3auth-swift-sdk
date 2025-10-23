import Foundation

/**
 List of possible web-based authentication errors.
 */
public enum Web3AuthError: Error {
    case noBundleIdentifierFound
    case userCancelled
    case appCancelled
    case unknownError
    case runtimeError(String)
    case decodingError
    case encodingError
    case noUserFound
    case mfaAlreadyEnabled
    case mfaNotEnabled
    case invalidOrMissingRedirectURI
    case inValidLogin
    case enabledMfaNotAllowed
    case ed25519KeyNotFound
    case ed25519CustomAuthError
}

extension Web3AuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noBundleIdentifierFound:
            return "No Bundle identifier found"
        case .userCancelled:
            return "User cancelled"
        case .appCancelled:
            return "App cancelled"
        case .unknownError:
            return "Unknown error"
        case let .runtimeError(msg):
            return "Runtime error \(msg)"
        case .decodingError:
            return "Decoding Error"
        case .encodingError:
            return "Encoding Error"
        case .noUserFound:
            return "No user found, please login again!"
        case .mfaAlreadyEnabled:
            return "MFA already enabled."
        case .mfaNotEnabled:
            return "MFA is not enabled. Please enable MFA first."
        case .invalidOrMissingRedirectURI:
            return "Invalid or missing redirect URI."
        case .inValidLogin:
            return "Invalid login credentials."
        case .enabledMfaNotAllowed:
            return "Enabling MFA is not allowed for this user."
        case .ed25519CustomAuthError:
            return "Ed25519 key is not available for custom auth connection"
        case .ed25519KeyNotFound:
            return "No valid Ed25519 private key found"
        }
    }
}
