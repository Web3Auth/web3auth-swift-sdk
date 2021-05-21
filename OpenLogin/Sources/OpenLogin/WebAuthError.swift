import Foundation

/**
 List of possible web-based authentication errors with OpenLogin.
 */
public enum WebAuthError: Error {
    case unknown
    case noBundleIdentifierFound
}
