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
}

extension Web3AuthError:LocalizedError{
    public var errorDescription: String?{
        switch self {
        case .noBundleIdentifierFound:
            return "No Bundle identifier found"
        case .userCancelled:
            return "User cancelled"
        case .appCancelled:
            return "App cancelled"
        case .unknownError:
            return "Unknown error"
        case .runtimeError(let msg):
            return "Runtime error \(msg)"
        case .decodingError:
            return "Decoding Error"
        case .encodingError:
            return "Encoding Error"
        case .noUserFound:
            return "No userInfo found, please login again"
        }
    }
}
