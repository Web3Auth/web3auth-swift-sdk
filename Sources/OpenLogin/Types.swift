import Foundation
import UIKit
import AuthenticationServices
import SafariServices

public enum UxModeType: String {
    case popup = "POPUP"
    case redirect = "REDIRECT"
}

public enum TypeOfLogin: String {
    case google = "google"
    case facebook = "facebook"
    case reddit = "reddit"
    case discord = "discord"
    case twitch = "twitch"
    case apple = "apple"
    case github = "github"
    case linkedin = "linkedin"
    case twitter = "twitter"
    case weibo = "weibo"
    case line = "line"
    case email_password = "email_password"
    case passwordless = "passwordless"
    case jwt = "jwt"
    case webauthn = "webauthn"
}

public struct OLWhiteLabelData: Encodable {
    public init(name: String? = nil, logoLight: String? = nil, logoDark: String? = nil, defaultLanguage: String? = nil, dark: Bool? = nil, theme: [String : String]? = nil) {
        self.name = name
        self.logoLight = logoLight
        self.logoDark = logoDark
        self.defaultLanguage = defaultLanguage
        self.dark = dark
        self.theme = theme
    }
    
    let name: String?
    let logoLight: String?
    let logoDark: String?
    let defaultLanguage: String?
    let dark: Bool?
    let theme: [String: String]?
}

public struct OLLoginConfig: Encodable {
    public init(verifier: String, typeOfLogin: TypeOfLogin, name: String, description: String? = nil, clientId: String? = nil, verifierSubIdentifier: String? = nil, logoHover: String? = nil, logoLight: String? = nil, logoDark: String? = nil, mainOption: Bool? = nil, showOnModal: Bool? = nil, showOnDesktop: Bool? = nil, showOnMobile: Bool? = nil) {
        self.verifier = verifier
        self.typeOfLogin = typeOfLogin
        self.name = name
        self.description = description
        self.clientId = clientId
        self.verifierSubIdentifier = verifierSubIdentifier
        self.logoHover = logoHover
        self.logoLight = logoLight
        self.logoDark = logoDark
        self.mainOption = mainOption
        self.showOnModal = showOnModal
        self.showOnDesktop = showOnDesktop
        self.showOnMobile = showOnMobile
    }
    
    let verifier: String
    let typeOfLogin: TypeOfLogin
    let name: String
    let description: String?
    let clientId: String?
    let verifierSubIdentifier: String?
    let logoHover: String?
    let logoLight: String?
    let logoDark: String?
    let mainOption: Bool?
    let showOnModal: Bool?
    let showOnDesktop: Bool?
    let showOnMobile: Bool?
}

public struct OLInitParams: Encodable {
    public init(clientId: String, network: Network, sdkUrl: URL = URL(string: "https://sdk.openlogin.com")!, no3PC: Bool? = nil, redirectUrl: String? = nil, uxMode: UxModeType? = nil, replaceUrlOnRedirect: Bool? = nil, originData: [String : Any]? = nil, loginConfig: [String : OLLoginConfig]? = nil, whiteLabel: OLWhiteLabelData? = nil) {
        self.clientId = clientId
        self.network = network
        self.sdkUrl = sdkUrl
        self.no3PC = no3PC
        self.redirectUrl = redirectUrl
        self.uxMode = uxMode
        self.replaceUrlOnRedirect = replaceUrlOnRedirect
        self.originData = originData
        self.loginConfig = loginConfig
        self.whiteLabel = whiteLabel
    }
    
    public init(clientId: String, network: Network, sdkUrl: URL = URL(string: "https://sdk.openlogin.com")!) {
        self.clientId = clientId
        self.network = network
        self.sdkUrl = sdkUrl
        self.no3PC = nil
        self.redirectUrl = nil
        self.uxMode = nil
        self.replaceUrlOnRedirect = nil
        self.originData = nil
        self.loginConfig = nil
        self.whiteLabel = nil
    }
    
    public init(clientId: String, network: Network) {
        self.clientId = clientId
        self.network = network
        self.no3PC = nil
        self.redirectUrl = nil
        self.uxMode = nil
        self.replaceUrlOnRedirect = nil
        self.originData = nil
        self.loginConfig = nil
        self.whiteLabel = nil
    }
    
    let clientId: String
    let network: Network
    var sdkUrl: URL = URL(string: "https://sdk.openlogin.com")!
    let no3PC: Bool?
    let redirectUrl: String?
    let uxMode: UxModeType?
    let replaceUrlOnRedirect: Bool?
    let originData: [String: Any]?
    let loginConfig: [String: OLLoginConfig]?
    let whiteLabel: OLWhiteLabelData?
}

public struct OLLoginParams: Encodable {
    public init(loginProvider: OpenLoginProvider? = nil, relogin: Bool? = nil, fastLogin: Bool? = nil, skipTKey: Bool? = nil, extraLoginOptions: Dictionary<String, Any>? = nil, redirectUrl: String? = nil, appState: String? = nil) {
        self.loginProvider = loginProvider?.rawValue
        self.fastLogin = fastLogin
        self.relogin = relogin
        self.skipTKey = skipTKey
        self.extraLoginOptions = extraLoginOptions
        self.redirectUrl = redirectUrl
        self.appState = appState
    }
     
    public init(loginProvider: OpenLoginProvider? = nil) {
        self.loginProvider = loginProvider?.rawValue
        self.fastLogin = nil
        self.relogin = nil
        self.skipTKey = nil
        self.extraLoginOptions = nil
        self.redirectUrl = nil
        self.appState = nil
    }
    
    public init(loginProvider: String? = nil, relogin: Bool? = nil, fastLogin: Bool? = nil, skipTKey: Bool? = nil, extraLoginOptions: Dictionary<String, Any>? = nil, redirectUrl: String? = nil, appState: String? = nil) {
        self.loginProvider = loginProvider
        self.fastLogin = fastLogin
        self.relogin = relogin
        self.skipTKey = skipTKey
        self.extraLoginOptions = extraLoginOptions
        self.redirectUrl = redirectUrl
        self.appState = appState
    }
     
    public init(loginProvider: String? = nil) {
        self.loginProvider = loginProvider
        self.fastLogin = nil
        self.relogin = nil
        self.skipTKey = nil
        self.extraLoginOptions = nil
        self.redirectUrl = nil
        self.appState = nil
    }
    
    let loginProvider: String?
    let fastLogin: Bool?
    let relogin: Bool?
    let skipTKey: Bool?
    let extraLoginOptions: Dictionary<String, Any>?
    let redirectUrl: String?
    let appState: String?
}


