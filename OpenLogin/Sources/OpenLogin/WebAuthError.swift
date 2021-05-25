import Foundation

public enum WebAuthError: Error {
    case noBundleIdentifierFound
    case userCancelled
    case unknownError
}
