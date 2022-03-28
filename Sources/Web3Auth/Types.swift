import Foundation
import UIKit
import AuthenticationServices
import SafariServices

public enum TypeOfLogin: String, Encodable {
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

public struct W3AWhiteLabelData: Encodable {
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

public struct W3ALoginConfig: Encodable {
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

public struct W3AInitParams: Encodable {
    public init(clientId: String, network: Network, sdkUrl: URL = URL(string: "https://sdk.openlogin.com")!, redirectUrl: String? = nil, loginConfig: [String : W3ALoginConfig]? = nil, whiteLabel: W3AWhiteLabelData? = nil) {
        self.clientId = clientId
        self.network = network
        self.sdkUrl = sdkUrl
        self.redirectUrl = redirectUrl
        self.loginConfig = loginConfig
        self.whiteLabel = whiteLabel
    }
    
    public init(clientId: String, network: Network, sdkUrl: URL = URL(string: "https://sdk.openlogin.com")!) {
        self.clientId = clientId
        self.network = network
        self.sdkUrl = sdkUrl
        self.redirectUrl = nil
        self.loginConfig = nil
        self.whiteLabel = nil
    }
    
    public init(clientId: String, network: Network) {
        self.clientId = clientId
        self.network = network
        self.redirectUrl = nil
        self.loginConfig = nil
        self.whiteLabel = nil
    }
    
    let clientId: String
    let network: Network
    var sdkUrl: URL = URL(string: "https://sdk.openlogin.com")!
    var redirectUrl: String?
    let loginConfig: [String: W3ALoginConfig]?
    let whiteLabel: W3AWhiteLabelData?
}

public struct W3ALoginParams: Encodable {
    
    public init() {
        self.loginProvider = nil
        self.relogin = nil
        self.dappShare = nil
        self.extraLoginOptions = nil
        self.redirectUrl = nil
        self.appState = nil
    }
    
    public init(loginProvider: Web3AuthProvider?, relogin: Bool? = nil, dappShare: String? = nil, extraLoginOptions: ExtraLoginOptions? = nil, redirectUrl: String? = nil, appState: String? = nil) {
        self.loginProvider = loginProvider?.rawValue
        self.relogin = relogin
        self.dappShare = dappShare
        self.extraLoginOptions = extraLoginOptions
        self.redirectUrl = redirectUrl
        self.appState = appState
    }
    
    public init(loginProvider: String?, relogin: Bool? = nil, dappShare: String? = nil, extraLoginOptions: ExtraLoginOptions? = nil, redirectUrl: String? = nil, appState: String? = nil) {
        self.loginProvider = loginProvider
        self.relogin = relogin
        self.dappShare = dappShare
        self.extraLoginOptions = extraLoginOptions
        self.redirectUrl = redirectUrl
        self.appState = appState
    }
    
    let loginProvider: String?
    let relogin: Bool?
    let dappShare: String?
    let extraLoginOptions: ExtraLoginOptions?
    let redirectUrl: String?
    let appState: String?
}

public struct ExtraLoginOptions: Encodable {
    public init(display: String?, prompt: String?, max_age: String?, ui_locales: String?, id_token_hint: String?, login_hint: String?, acr_values: String?, scope: String?, audience: String?, connection: String?, domain: String?, client_id: String?, redirect_uri: String?, leeway: Int?, verifierIdField: String?, isVerifierIdCaseSensitive: Bool?) {
        self.display = display
        self.prompt = prompt
        self.max_age = max_age
        self.ui_locales = ui_locales
        self.id_token_hint = id_token_hint
        self.login_hint = login_hint
        self.acr_values = acr_values
        self.scope = scope
        self.audience = audience
        self.connection = connection
        self.domain = domain
        self.client_id = client_id
        self.redirect_uri = redirect_uri
        self.leeway = leeway
        self.verifierIdField = verifierIdField
        self.isVerifierIdCaseSensitive = isVerifierIdCaseSensitive
    }
    
    let display: String?
    let prompt: String?
    let max_age: String?
    let ui_locales: String?
    let id_token_hint: String?
    let login_hint: String?
    let acr_values: String?
    let scope: String?
    let audience: String?
    let connection: String?
    let domain: String?
    let client_id: String?
    let redirect_uri: String?
    let leeway: Int?
    let verifierIdField: String?
    let isVerifierIdCaseSensitive: Bool?
}

struct SdkUrlParams: Encodable {
    internal init(initParams: W3AInitParams, params: W3ALoginParams) {
        self.initParams = initParams
        self.params = params
    }
    let initParams: W3AInitParams
    let params: W3ALoginParams
    
    enum CodingKeys: String, CodingKey {
        case initParams = "init"
        case params
    }
}
