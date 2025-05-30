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
        }
    }
}
