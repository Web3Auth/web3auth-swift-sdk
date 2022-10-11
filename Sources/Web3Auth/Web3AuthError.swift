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
    
}
