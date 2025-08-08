import Foundation
import Segment

final class AnalyticsManager {
    static let shared = AnalyticsManager()

    #if DEBUG
    private let SEGMENT_WRITE_KEY = SegmentKeys.development
    #else
    private let SEGMENT_WRITE_KEY = SegmentKeys.production
    #endif

    private(set) var analytics: Analytics?
    private var isInitialized = false
    private var globalProperties: [String: Any] = [:]

    private init() {}

    func initialize() {
        guard !isInitialized else { return }

        let configuration = Configuration(writeKey: SEGMENT_WRITE_KEY)
        let analyticsInstance = Analytics(configuration: configuration)
        self.analytics = analyticsInstance
        isInitialized = true
    }

    func setGlobalProperties(_ properties: [String: Any]) {
        globalProperties = properties
    }

    func trackEvent(_ eventName: String, properties: [String: Any]? = nil) {
        guard let analytics = analytics else { return }

        var combinedProps = globalProperties
        properties?.forEach { combinedProps[$0.key] = $0.value }

        analytics.track(name: eventName, properties: combinedProps)
    }

    func trackScreen(name: String, properties: [String: Any]? = nil) {
        guard let analytics = analytics else { return }

        analytics.screen(title: name, properties: properties)
    }
    
    func identify(userId: String, traits: [String: Any]? = nil) {
        guard let analytics = analytics else { return }
        analytics.identify(userId: userId, traits: traits ?? [:])
    }
}

enum SegmentKeys {
    static let production = "f6LbNqCeVRf512ggdME4b6CyflhF1tsX"
    static let development = "rpE5pCcpA6ME2oFu2TbuVydhOXapjHs3"
}

enum AnalyticsEvents {
    static let sdkInitializationCompleted = "SDK Initialization Completed"
    static let sdkInitializationFailed = "SDK Initialization Failed"
    static let connectionStarted = "Connection Started"
    static let connectionCompleted = "Connection Completed"
    static let connectionFailed = "Connection Failed"
    static let mfaEnablementStarted = "MFA Enablement Started"
    static let mfaEnablementCompleted = "MFA Enablement Completed"
    static let mfaEnablementFailed = "MFA Enablement Failed"
    static let mfaManagementStarted = "MFA Management Started"
    static let mfaManagementFailed = "MFA Management Failed"
    static let mfaManagementCompleted = "MFA Management Completed"
    static let walletUIClicked = "Wallet UI Clicked"
    static let walletServicesFailed = "Wallet Services Failed"
    static let logoutStarted = "Logout Started"
    static let logoutCompleted = "Logout Completed"
    static let logoutFailed = "Logout Failed"
    static let requestFunctionStarted = "Request Function Started"
    static let requestFunctionCompleted = "Request Function Completed"
    static let requestFunctionFailed = "Request Function Failed"

    static let iosSdkVersion = "12.0.0"
}

enum AnalyticsSdkType {
    static let ios = "ios"
    static let flutter = "flutter"
}

