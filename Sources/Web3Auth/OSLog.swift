import OSLog

public let subsystem = Bundle.main.bundleIdentifier ?? "com.torus.Web3Auth"
var web3AuthLogType = OSLogType.default

public struct Web3AuthLogger {
    static let inactiveLog = OSLog.disabled
    static let core = OSLog(subsystem: subsystem, category: "core")
    static let web3AuthNetwork = OSLog(subsystem: subsystem, category: "web3AuthNetwork")
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
func getTorusLogger(log: OSLog = .default, type: OSLogType = .default) -> OSLog {
    var logCheck: OSLog { web3AuthLogType.rawValue <= type.rawValue ? log : Web3AuthLogger.inactiveLog }
    return logCheck
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
func log(_ message: StaticString, dso: UnsafeRawPointer? = #dsohandle, log: OSLog = .default, type: OSLogType = .default, _ args: CVarArg...) {
    var logCheck: OSLog { web3AuthLogType.rawValue <= type.rawValue ? log : Web3AuthLogger.inactiveLog }
    os_log(message, dso: dso, log: logCheck, type: type, args)
}
