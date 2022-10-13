import Foundation

struct Signature:Codable{
    let r:String
    let s:String
}


struct SessionLogoutDataModel: Codable {
    var key: String
    var data: String
    var signature: String
    var timeout: Int
}

public struct ECIES:Codable {
    public init(iv: String, ephemPublicKey: String, ciphertext: String, mac: String) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.ciphertext = ciphertext
        self.mac = mac
    }

    var iv: String
    var ephemPublicKey: String
    var ciphertext: String
    var mac: String
}

public enum SUPPORTED_KEY_CURVES: String, Codable {
    case SECP256K1 = "secp256k1"
    case ED25519 = "ed25519"
}

public enum MFALevel: String, Codable {
    case DEFAULT = "default"
    case OPTIONAL = "optional"
    case MANDATORY = "mandatory"
    case NONE = "none"
}

public enum TypeOfLogin: String, Codable {
    case google
    case facebook
    case reddit
    case discord
    case twitch
    case apple
    case github
    case linkedin
    case twitter
    case weibo
    case line
    case email_password
    case passwordless
    case jwt
}

public struct W3AWhiteLabelData: Codable {
    public init(name: String? = nil, logoLight: String? = nil, logoDark: String? = nil, defaultLanguage: String? = nil, dark: Bool? = nil, theme: [String: String]? = nil) {
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

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        logoLight = try values.decodeIfPresent(String.self, forKey: .logoLight)
        logoDark = try values.decodeIfPresent(String.self, forKey: .logoDark)
        defaultLanguage = try values.decodeIfPresent(String.self, forKey: .defaultLanguage)
        dark = try values.decodeIfPresent(Bool.self, forKey: .dark)
        theme = try values.decodeIfPresent([String: String].self, forKey: .theme)
    }
}


public struct W3ALoginConfig: Codable {
    public init(verifier: String, typeOfLogin: TypeOfLogin, name: String, description: String? = nil, clientId: String? = nil,
                verifierSubIdentifier: String? = nil, logoHover: String? = nil, logoLight: String? = nil, logoDark: String? = nil, mainOption: Bool? = nil,
                showOnModal: Bool? = nil, showOnDesktop: Bool? = nil, showOnMobile: Bool? = nil) {
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

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        verifier = try values.decode(String.self, forKey: .verifier)
        typeOfLogin = try values.decode(TypeOfLogin.self, forKey: .typeOfLogin)
        name = try values.decode(String.self, forKey: .name)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        clientId = try values.decodeIfPresent(String.self, forKey: .clientId)
        verifierSubIdentifier = try values.decodeIfPresent(String.self, forKey: .verifierSubIdentifier)
        logoHover = try values.decodeIfPresent(String.self, forKey: .logoHover)
        logoLight = try values.decodeIfPresent(String.self, forKey: .logoLight)
        logoDark = try values.decodeIfPresent(String.self, forKey: .logoDark)
        mainOption = try values.decodeIfPresent(Bool.self, forKey: .mainOption)
        showOnModal = try values.decodeIfPresent(Bool.self, forKey: .showOnModal)
        showOnDesktop = try values.decodeIfPresent(Bool.self, forKey: .showOnDesktop)
        showOnMobile = try values.decodeIfPresent(Bool.self, forKey: .showOnMobile)
    }
}


public struct W3AInitParams: Codable {
    public init(clientId: String, network: Network, sdkUrl: URL = URL(string: "https://sdk.openlogin.com")!, redirectUrl: String? = nil,
                loginConfig: [String: W3ALoginConfig]? = nil, whiteLabel: W3AWhiteLabelData? = nil) {
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
        redirectUrl = nil
        loginConfig = nil
        whiteLabel = nil
    }

    public init(clientId: String, network: Network) {
        self.clientId = clientId
        self.network = network
        redirectUrl = nil
        loginConfig = nil
        whiteLabel = nil
    }

    let clientId: String
    let network: Network
    var sdkUrl: URL = URL(string: "https://sdk.openlogin.com")!
    var redirectUrl: String?
    let loginConfig: [String: W3ALoginConfig]?
    let whiteLabel: W3AWhiteLabelData?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        clientId = try values.decode(String.self, forKey: .clientId)
        network = try values.decode(Network.self, forKey: .network)
        let customSdkUrl = try values.decodeIfPresent(String.self, forKey: .sdkUrl)
        if customSdkUrl != nil {
            sdkUrl = URL(string: customSdkUrl!)!
        }
        redirectUrl = try values.decodeIfPresent(String.self, forKey: .redirectUrl)
        loginConfig = try values.decodeIfPresent([String: W3ALoginConfig].self, forKey: .loginConfig)
        whiteLabel = try values.decodeIfPresent(W3AWhiteLabelData.self, forKey: .whiteLabel)
    }
}

public struct W3ALoginParams: Codable {

    public init() {
        self.loginProvider = nil
        self.dappShare = nil
        self.extraLoginOptions = nil
        self.redirectUrl = nil
        self.appState = nil
        self.mfaLevel = nil
        self.sessionTime = 86400
        self.curve = .SECP256K1
    }

    public init(loginProvider: Web3AuthProvider?, dappShare: String? = nil,
                extraLoginOptions: ExtraLoginOptions? = nil, redirectUrl: String? = nil, appState: String? = nil,
                mfaLevel: MFALevel? = nil, sessionTime: Int = 86400, curve: SUPPORTED_KEY_CURVES = .SECP256K1) {
        self.loginProvider = loginProvider?.rawValue
        self.dappShare = dappShare
        self.extraLoginOptions = extraLoginOptions
        self.redirectUrl = redirectUrl
        self.appState = appState
        self.mfaLevel = mfaLevel
        self.sessionTime = min(7 * 86400, sessionTime)
        self.curve = curve
    }

    public init(loginProvider: String?, dappShare: String? = nil,
                extraLoginOptions: ExtraLoginOptions? = nil, redirectUrl: String? = nil, appState: String? = nil,
                mfaLevel: MFALevel? = nil, sessionTime: Int = 86400, curve: SUPPORTED_KEY_CURVES = .SECP256K1) {
        self.loginProvider = loginProvider
        self.dappShare = dappShare
        self.extraLoginOptions = extraLoginOptions
        self.redirectUrl = redirectUrl
        self.appState = appState
        self.mfaLevel = mfaLevel
        self.sessionTime = min(7 * 86400, sessionTime)
        self.curve = curve
    }

    let loginProvider: String?
    var dappShare: String?
    let extraLoginOptions: ExtraLoginOptions?
    let redirectUrl: String?
    let appState: String?
    let mfaLevel: MFALevel?
    let sessionTime: Int
    let curve: SUPPORTED_KEY_CURVES

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        loginProvider = try values.decodeIfPresent(String.self, forKey: .loginProvider)
        dappShare = try values.decodeIfPresent(String.self, forKey: .dappShare)
        extraLoginOptions = try values.decodeIfPresent(ExtraLoginOptions.self, forKey: .extraLoginOptions)
        redirectUrl = try values.decodeIfPresent(String.self, forKey: .redirectUrl)
        appState = try values.decodeIfPresent(String.self, forKey: .appState)
        mfaLevel = try values.decodeIfPresent(MFALevel.self, forKey: .mfaLevel)
        sessionTime = try values.decodeIfPresent(Int.self, forKey: .sessionTime) ?? 86400
        curve = try values.decodeIfPresent(SUPPORTED_KEY_CURVES.self, forKey: .curve) ?? .SECP256K1
    }
}

public struct ExtraLoginOptions: Codable {
    public init(display: String?, prompt: String?, max_age: String?, ui_locales: String?,
                id_token_hint: String?, id_token: String?, login_hint: String?, acr_values: String?, scope: String?,
                audience: String?, connection: String?, domain: String?, client_id: String?, redirect_uri: String?, leeway: Int?, verifierIdField: String?, isVerifierIdCaseSensitive: Bool?) {
        self.display = display
        self.prompt = prompt
        self.max_age = max_age
        self.ui_locales = ui_locales
        self.id_token_hint = id_token_hint
        self.id_token = id_token
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
    let id_token: String?
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

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        display = try values.decodeIfPresent(String.self, forKey: .display)
        prompt = try values.decodeIfPresent(String.self, forKey: .prompt)
        max_age = try values.decodeIfPresent(String.self, forKey: .max_age)
        ui_locales = try values.decodeIfPresent(String.self, forKey: .ui_locales)
        id_token_hint = try values.decodeIfPresent(String.self, forKey: .id_token_hint)
        id_token = try values.decodeIfPresent(String.self, forKey: .id_token)
        login_hint = try values.decodeIfPresent(String.self, forKey: .login_hint)
        acr_values = try values.decodeIfPresent(String.self, forKey: .acr_values)
        scope = try values.decodeIfPresent(String.self, forKey: .scope)
        audience = try values.decodeIfPresent(String.self, forKey: .audience)
        connection = try values.decodeIfPresent(String.self, forKey: .connection)
        domain = try values.decodeIfPresent(String.self, forKey: .domain)
        client_id = try values.decodeIfPresent(String.self, forKey: .client_id)
        redirect_uri = try values.decodeIfPresent(String.self, forKey: .redirect_uri)
        leeway = try values.decodeIfPresent(Int.self, forKey: .leeway)
        verifierIdField = try values.decodeIfPresent(String.self, forKey: .verifierIdField)
        isVerifierIdCaseSensitive = try values.decodeIfPresent(Bool.self, forKey: .isVerifierIdCaseSensitive)
    }
}

struct SdkUrlParams: Codable {
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
