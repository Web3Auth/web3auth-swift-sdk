import Foundation
import UIKit
import AuthenticationServices
import SafariServices

public enum UxModeType: String, Encodable {
    case popup = "POPUP"
    case redirect = "REDIRECT"
}

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
    public init(clientId: String, network: Network, sdkUrl: URL = URL(string: "https://sdk.openlogin.com")!, no3PC: Bool? = nil, redirectUrl: String? = nil, uxMode: UxModeType? = nil, replaceUrlOnRedirect: Bool? = nil, originData: [String : AnyEncodable]? = nil, loginConfig: [String : OLLoginConfig]? = nil, whiteLabel: OLWhiteLabelData? = nil) {
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
    var redirectUrl: String?
    let uxMode: UxModeType?
    let replaceUrlOnRedirect: Bool?
    let originData: [String: AnyEncodable]?
    let loginConfig: [String: OLLoginConfig]?
    let whiteLabel: OLWhiteLabelData?
}

public struct OLLoginParams: Encodable {
    
    public init() {
        self.loginProvider = nil
        self.fastLogin = nil
        self.relogin = nil
        self.skipTKey = nil
        self.extraLoginOptions = nil
        self.redirectUrl = nil
        self.appState = nil
    }
    
    public init(loginProvider: OpenLoginProvider?, relogin: Bool? = nil, fastLogin: Bool? = nil, skipTKey: Bool? = nil, extraLoginOptions: ExtraLoginOptions? = nil, redirectUrl: String? = nil, appState: String? = nil) {
        self.loginProvider = loginProvider?.rawValue
        self.fastLogin = fastLogin
        self.relogin = relogin
        self.skipTKey = skipTKey
        self.extraLoginOptions = extraLoginOptions
        self.redirectUrl = redirectUrl
        self.appState = appState
    }
    
    public init(loginProvider: String?, relogin: Bool? = nil, fastLogin: Bool? = nil, skipTKey: Bool? = nil, extraLoginOptions: ExtraLoginOptions? = nil, redirectUrl: String? = nil, appState: String? = nil) {
        self.loginProvider = loginProvider
        self.fastLogin = fastLogin
        self.relogin = relogin
        self.skipTKey = skipTKey
        self.extraLoginOptions = extraLoginOptions
        self.redirectUrl = redirectUrl
        self.appState = appState
    }
    
    let loginProvider: String?
    let fastLogin: Bool?
    let relogin: Bool?
    let skipTKey: Bool?
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
    internal init(initParams: OLInitParams, params: OLLoginParams) {
        self.initParams = initParams
        self.params = params
    }
    let initParams: OLInitParams
    let params: OLLoginParams
    
    enum CodingKeys: String, CodingKey {
        case initParams = "init"
        case params
    }
}
