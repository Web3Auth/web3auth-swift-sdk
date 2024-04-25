import Foundation

public struct Signature: Codable {
    let r: String
    let s: String

    public init(r: String, s: String) {
        self.r = r
        self.s = s
    }
}

struct SessionLogoutDataModel: Codable {
    var key: String
    var data: String
    var signature: String
    var timeout: Int

    public init(key: String, data: String, signature: String, timeout: Int) {
        self.key = key
        self.data = data
        self.signature = signature
        self.timeout = timeout
    }
}

public struct ECIES: Codable {
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

public struct SessionResponse: Codable {
    let sessionId: String
}

public struct SignResponse: Codable {
    public let success: Bool
    public let result: String?
    public let error: String?
    
    public init(success: Bool, result: String?, error: String?) {
        self.success = success
        self.result = result
        self.error = error
    }
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

public enum ChainNamespace: String, Codable {
    case eip155
    case solana
}

public struct W3AWhiteLabelData: Codable {
    public init(appName: String? = nil, logoLight: String? = nil, logoDark: String? = nil, defaultLanguage: Language? = Language.en, mode: ThemeModes? = ThemeModes.auto, theme: [String: String]? = nil, appUrl: String? = nil, useLogoLoader: Bool? = false) {
        self.appName = appName
        self.logoLight = logoLight
        self.logoDark = logoDark
        self.defaultLanguage = defaultLanguage
        self.mode = mode
        self.theme = theme
        self.appUrl = appUrl
        self.useLogoLoader = useLogoLoader
    }

    let appName: String?
    let logoLight: String?
    let logoDark: String?
    let defaultLanguage: Language?
    let mode: ThemeModes?
    let theme: [String: String]?
    let appUrl: String?
    let useLogoLoader: Bool?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        appName = try values.decodeIfPresent(String.self, forKey: .appName)
        logoLight = try values.decodeIfPresent(String.self, forKey: .logoLight)
        logoDark = try values.decodeIfPresent(String.self, forKey: .logoDark)
        defaultLanguage = try values.decodeIfPresent(Language.self, forKey: .defaultLanguage) ?? Language.en
        mode = try values.decodeIfPresent(ThemeModes.self, forKey: .mode) ?? ThemeModes.auto
        theme = try values.decodeIfPresent([String: String].self, forKey: .theme)
        appUrl = try values.decodeIfPresent(String.self, forKey: .appUrl)
        useLogoLoader = try values.decodeIfPresent(Bool.self, forKey: .useLogoLoader)
    }
}

public struct W3ALoginConfig: Codable {
    public init(verifier: String, typeOfLogin: TypeOfLogin, name: String? = nil, description: String? = nil, clientId: String,
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
    let name: String?
    let description: String?
    let clientId: String
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
        name = try values.decodeIfPresent(String.self, forKey: .name)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        clientId = try values.decode(String.self, forKey: .clientId)
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
    public init(clientId: String, network: Network, buildEnv: BuildEnv? = BuildEnv.production, sdkUrl: URL? = nil, walletSdkUrl: URL? = nil, redirectUrl: String? = nil, loginConfig: [String: W3ALoginConfig]? = nil, whiteLabel: W3AWhiteLabelData? = nil, chainNamespace: ChainNamespace? = ChainNamespace.eip155, useCoreKitKey: Bool? = false, mfaSettings: MfaSettings? = nil, sessionTime: Int = 86400) {
        self.clientId = clientId
        self.network = network
        self.buildEnv = buildEnv
        if sdkUrl != nil {
                    self.sdkUrl = sdkUrl
                } else {
                    self.sdkUrl = URL(string: getSdkUrl(buildEnv: self.buildEnv))
                }
        if walletSdkUrl != nil {
                    self.walletSdkUrl = walletSdkUrl
                } else {
                    self.walletSdkUrl = URL(string: getWalletSdkUrl(buildEnv: self.buildEnv))
                }
        self.redirectUrl = redirectUrl
        self.loginConfig = loginConfig
        self.whiteLabel = whiteLabel
        self.chainNamespace = chainNamespace
        self.useCoreKitKey = useCoreKitKey
        self.mfaSettings = mfaSettings
        self.sessionTime = min(7 * 86400, sessionTime)
        self.chainConfig = nil
    }

    public init(clientId: String, network: Network) {
        self.clientId = clientId
        self.network = network
        buildEnv = BuildEnv.production
        sdkUrl = URL(string: getSdkUrl(buildEnv: buildEnv))
        walletSdkUrl = URL(string: getWalletSdkUrl(buildEnv: self.buildEnv))
        redirectUrl = nil
        loginConfig = nil
        whiteLabel = nil
        chainNamespace = ChainNamespace.eip155
        useCoreKitKey = false
        mfaSettings = nil
        sessionTime = 86400
        chainConfig = nil
    }

    let clientId: String
    let network: Network
    let buildEnv: BuildEnv?
    var sdkUrl: URL?
    var walletSdkUrl: URL?
    var redirectUrl: String?
    let loginConfig: [String: W3ALoginConfig]?
    let whiteLabel: W3AWhiteLabelData?
    let chainNamespace: ChainNamespace?
    let useCoreKitKey: Bool?
    let mfaSettings: MfaSettings?
    let sessionTime: Int
    var chainConfig: ChainConfig?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        clientId = try values.decode(String.self, forKey: .clientId)
        network = try values.decode(Network.self, forKey: .network)
        buildEnv = try values.decodeIfPresent(BuildEnv.self, forKey: .buildEnv) ?? BuildEnv.production
        let customSdkUrl = try values.decodeIfPresent(String.self, forKey: .sdkUrl)
        if customSdkUrl != nil {
            sdkUrl = URL(string: customSdkUrl!)!
        } else {
            sdkUrl = URL(string: getSdkUrl(buildEnv: buildEnv))
        }
        let customWalletSdkUrl = try values.decodeIfPresent(String.self, forKey: .walletSdkUrl)
        if customWalletSdkUrl != nil {
            walletSdkUrl = URL(string: customWalletSdkUrl!)!
        } else {
            walletSdkUrl = URL(string: getWalletSdkUrl(buildEnv: buildEnv))
        }
        redirectUrl = try values.decodeIfPresent(String.self, forKey: .redirectUrl)
        loginConfig = try values.decodeIfPresent([String: W3ALoginConfig].self, forKey: .loginConfig)
        whiteLabel = try values.decodeIfPresent(W3AWhiteLabelData.self, forKey: .whiteLabel)
        chainNamespace = try values.decodeIfPresent(ChainNamespace.self, forKey: .chainNamespace) ?? ChainNamespace.eip155
        useCoreKitKey = try values.decodeIfPresent(Bool.self, forKey: .useCoreKitKey)
        mfaSettings = try values.decodeIfPresent(MfaSettings.self, forKey: .mfaSettings)
        sessionTime = try values.decodeIfPresent(Int.self, forKey: .sessionTime) ?? 86400
        chainConfig = try values.decode(ChainConfig.self, forKey: .chainConfig)
    }
}

public func getSdkUrl(buildEnv: BuildEnv?) -> String {
    let openLoginVersion = "v8"

    switch buildEnv {
    case .staging:
        return "https://staging-auth.web3auth.io/\(openLoginVersion)"
    case .testing:
        return "https://develop-auth.web3auth.io"
    default:
        return "https://auth.web3auth.io/\(openLoginVersion)"
    }
}

public func getWalletSdkUrl(buildEnv: BuildEnv?) -> String {
    let walletServicesVersion = "v1"
    guard let buildEnv = buildEnv else {
        return "https://wallet.web3auth.io"
    }

    switch buildEnv {
    case .staging:
        return "https://staging-wallet.web3auth.io/\(walletServicesVersion)"
    case .testing:
        return "https://develop-wallet.web3auth.io"
    default:
        return "https://wallet.web3auth.io/\(walletServicesVersion)"
    }
}

public struct W3ALoginParams: Codable {

    public init(loginProvider: Web3AuthProvider, dappShare: String? = nil,
                extraLoginOptions: ExtraLoginOptions? = nil, redirectUrl: String? = nil, appState: String? = nil,
                mfaLevel: MFALevel? = nil, curve: SUPPORTED_KEY_CURVES = .SECP256K1, dappUrl: String? = nil) {
        self.loginProvider = loginProvider.rawValue
        self.dappShare = dappShare
        self.extraLoginOptions = extraLoginOptions
        self.redirectUrl = redirectUrl
        self.appState = appState
        self.mfaLevel = mfaLevel
        self.curve = curve
        self.dappUrl = dappUrl
    }

    public init(loginProvider: String, dappShare: String? = nil,
                extraLoginOptions: ExtraLoginOptions? = nil, redirectUrl: String? = nil, appState: String? = nil,
                mfaLevel: MFALevel? = nil, curve: SUPPORTED_KEY_CURVES = .SECP256K1, dappUrl: String? = nil) {
        self.loginProvider = loginProvider
        self.dappShare = dappShare
        self.extraLoginOptions = extraLoginOptions
        self.redirectUrl = redirectUrl
        self.appState = appState
        self.mfaLevel = mfaLevel
        self.curve = curve
        self.dappUrl = dappUrl
    }

    let loginProvider: String
    var dappShare: String?
    let extraLoginOptions: ExtraLoginOptions?
    var redirectUrl: String?
    let appState: String?
    let mfaLevel: MFALevel?
    let curve: SUPPORTED_KEY_CURVES
    let dappUrl: String?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        loginProvider = try values.decode(String.self, forKey: .loginProvider)
        dappShare = try values.decodeIfPresent(String.self, forKey: .dappShare)
        extraLoginOptions = try values.decodeIfPresent(ExtraLoginOptions.self, forKey: .extraLoginOptions)
        redirectUrl = try values.decodeIfPresent(String.self, forKey: .redirectUrl)
        appState = try values.decodeIfPresent(String.self, forKey: .appState)
        mfaLevel = try values.decodeIfPresent(MFALevel.self, forKey: .mfaLevel)
        curve = try values.decodeIfPresent(SUPPORTED_KEY_CURVES.self, forKey: .curve) ?? .SECP256K1
        dappUrl = try values.decode(String.self, forKey: .dappUrl)
    }
}

public struct ExtraLoginOptions: Codable {
    public init(display: String? = nil, prompt: String? = nil, max_age: String? = nil, ui_locales: String? = nil,
                id_token_hint: String? = nil, id_token: String? = nil, login_hint: String? = nil, acr_values: String? = nil, scope: String? = nil,
                audience: String? = nil, connection: String? = nil, domain: String? = nil, client_id: String? = nil, redirect_uri: String? = nil, leeway: Int? = 0, verifierIdField: String? = nil, isVerifierIdCaseSensitive: Bool? = false, additionalParams: [String : String]? = nil) {
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
        self.additionalParams = additionalParams
    }

    let display: String?
    let prompt: String?
    let max_age: String?
    let ui_locales: String?
    let id_token_hint: String?
    let id_token: String?
    var login_hint: String?
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
    let additionalParams: [String : String]?

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
        additionalParams = try values.decodeIfPresent([String : String].self, forKey: .additionalParams)
    }
}

public struct MfaSettings: Codable {
    public init(deviceShareFactor: MfaSetting? = nil, backUpShareFactor: MfaSetting? = nil, socialBackupFactor: MfaSetting? = nil, passwordFactor: MfaSetting? = nil, passkeysFactor: MfaSetting? = nil,
                                                            authenticatorFactor: MfaSetting? = nil) {
        self.deviceShareFactor = deviceShareFactor
        self.backUpShareFactor = backUpShareFactor
        self.socialBackupFactor = socialBackupFactor
        self.passwordFactor = passwordFactor
        self.passkeysFactor = passkeysFactor
        self.authenticatorFactor = authenticatorFactor
    }

    let deviceShareFactor: MfaSetting?
    let backUpShareFactor: MfaSetting?
    let socialBackupFactor: MfaSetting?
    let passwordFactor: MfaSetting?
    let passkeysFactor: MfaSetting?
    let authenticatorFactor: MfaSetting?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        deviceShareFactor = try values.decodeIfPresent(MfaSetting.self, forKey: .deviceShareFactor)
        backUpShareFactor = try values.decodeIfPresent(MfaSetting.self, forKey: .backUpShareFactor)
        socialBackupFactor = try values.decodeIfPresent(MfaSetting.self, forKey: .socialBackupFactor)
        passwordFactor = try values.decodeIfPresent(MfaSetting.self, forKey: .passwordFactor)
        passkeysFactor = try values.decodeIfPresent(MfaSetting.self, forKey: .passkeysFactor)
        authenticatorFactor = try values.decodeIfPresent(MfaSetting.self, forKey: .authenticatorFactor)
    }
}

public struct MfaSetting: Codable {
    public init(enable: Bool, priority: Int?, mandatory: Bool? = nil) {
        self.enable = enable
        self.priority = priority
        self.mandatory = mandatory
    }

    let enable: Bool
    let priority: Int?
    let mandatory: Bool?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        enable = try values.decode(Bool.self, forKey: .enable)
        priority = try values.decodeIfPresent(Int.self, forKey: .priority)
        mandatory = try values.decodeIfPresent(Bool.self, forKey: .mandatory)
    }
}

public struct ChainConfig: Codable {
    public init(chainNamespace: ChainNamespace = ChainNamespace.eip155, decimals: Int? = 18, blockExplorerUrl: String? = nil, chainId: String, displayName: String? = nil, logo: String? = nil, rpcTarget: String, ticker: String? = nil, tickerName: String? = nil) {
        self.chainNamespace = chainNamespace
        self.decimals = decimals
        self.blockExplorerUrl = blockExplorerUrl
        self.chainId = chainId
        self.displayName = displayName
        self.logo = logo
        self.rpcTarget = rpcTarget
        self.ticker = ticker
        self.tickerName = tickerName
    }

    public let chainNamespace: ChainNamespace
    public let decimals: Int?
    public let blockExplorerUrl: String?
    public let chainId: String?
    public let displayName: String?
    public let logo: String?
    public let rpcTarget: String
    public let ticker: String?
    public let tickerName: String?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        chainNamespace = try values.decodeIfPresent(ChainNamespace.self, forKey: .chainNamespace) ?? ChainNamespace.eip155
        decimals = try values.decodeIfPresent(Int.self, forKey: .decimals) ?? 18
        blockExplorerUrl = try values.decodeIfPresent(String.self, forKey: .blockExplorerUrl)
        chainId = try values.decodeIfPresent(String.self, forKey: .chainId)
        displayName = try values.decodeIfPresent(String.self, forKey: .displayName)
        logo = try values.decodeIfPresent(String.self, forKey: .logo)
        rpcTarget = try values.decodeIfPresent(String.self, forKey: .rpcTarget) ?? ""
        ticker = try values.decodeIfPresent(String.self, forKey: .ticker)
        tickerName = try values.decodeIfPresent(String.self, forKey: .tickerName)
    }
}

struct SdkUrlParams: Codable {
    let options: W3AInitParams
    let params: W3ALoginParams
    let actionType: String

    enum CodingKeys: String, CodingKey {
        case options = "options"
        case params
        case actionType
    }
}

struct WalletServicesParams: Codable {
    let options: W3AInitParams
    let params: W3ALoginParams

    enum CodingKeys: String, CodingKey {
        case options = "options"
        case params
    }
}

struct SetUpMFAParams: Codable {
    let options: W3AInitParams
    let params: [String: String?]
    let actionType: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case options = "options"
        case params
        case actionType
        case sessionId
    }
}
