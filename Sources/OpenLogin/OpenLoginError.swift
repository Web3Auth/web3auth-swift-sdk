import Foundation

/**
 List of possible web-based authentication errors.
 */
public enum OpenLoginError: Error {
    case noBundleIdentifierFound
    case userCancelled
    case appCancelled
    case unknownError
}
