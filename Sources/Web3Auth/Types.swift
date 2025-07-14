//TODO: Split up this file.

import Foundation
import FetchNodeDetails

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

public enum ChainNamespace: String, Codable {
    case eip155
    case solana
    case other
}

public struct WhiteLabelData: Codable {
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

public struct AuthConnectionConfig: Codable {
    public init(authConnectionId: String, authConnection: AuthConnection, name: String? = nil, description: String? = nil, clientId: String, groupedAuthConnectionId: String? = nil , logoHover: String? = nil, logoLight: String? = nil, logoDark: String? = nil, mainOption: Bool? = nil,
                showOnModal: Bool? = nil, showOnDesktop: Bool? = nil, showOnMobile: Bool? = nil, jwtParameters: ExtraLoginOptions? = nil) {
        self.authConnectionId = authConnectionId
        self.authConnection = authConnection
        self.name = name
        self.description = description
        self.clientId = clientId
        self.groupedAuthConnectionId = groupedAuthConnectionId
        self.logoHover = logoHover
        self.logoLight = logoLight
        self.logoDark = logoDark
        self.mainOption = mainOption
        self.showOnModal = showOnModal
        self.showOnDesktop = showOnDesktop
        self.showOnMobile = showOnMobile
        self.jwtParameters = jwtParameters
    }

    let authConnectionId: String
    let authConnection: AuthConnection
    let name: String?
    let description: String?
    let clientId: String
    let groupedAuthConnectionId: String?
    let logoHover: String?
    let logoLight: String?
    let logoDark: String?
    let mainOption: Bool?
    let showOnModal: Bool?
    let showOnDesktop: Bool?
    let showOnMobile: Bool?
    let jwtParameters: ExtraLoginOptions?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        authConnectionId = try values.decode(String.self, forKey: .authConnectionId)
        authConnection = try values.decode(AuthConnection.self, forKey: .authConnection)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        clientId = try values.decode(String.self, forKey: .clientId)
        groupedAuthConnectionId = try values.decodeIfPresent(String.self, forKey: .groupedAuthConnectionId)
        logoHover = try values.decodeIfPresent(String.self, forKey: .logoHover)
        logoLight = try values.decodeIfPresent(String.self, forKey: .logoLight)
        logoDark = try values.decodeIfPresent(String.self, forKey: .logoDark)
        mainOption = try values.decodeIfPresent(Bool.self, forKey: .mainOption)
        showOnModal = try values.decodeIfPresent(Bool.self, forKey: .showOnModal)
        showOnDesktop = try values.decodeIfPresent(Bool.self, forKey: .showOnDesktop)
        showOnMobile = try values.decodeIfPresent(Bool.self, forKey: .showOnMobile)
        jwtParameters = try values.decodeIfPresent(ExtraLoginOptions.self, forKey: .jwtParameters)
    }
}

public struct Web3AuthOptions: Codable {
    public init(clientId: String, redirectUrl: String, originData: [String: String]? = nil, authBuildEnv: BuildEnv? = .production, sdkUrl: String? = nil,
                storageServerUrl: String? = nil,sessionSocketUrl: String? = nil, authConnectionConfig: [AuthConnectionConfig]? = nil,
                whiteLabel: WhiteLabelData? = nil, dashboardUrl: String? = nil, accountAbstractionConfig: String? = nil, walletSdkUrl: String? = nil,
                 includeUserDataInToken: Bool? = true, chains: [Chains]? = nil, defaultChainId: String? = "0x1", enableLogging: Bool? = false, sessionTime: Int = 30 * 86400, web3AuthNetwork: Web3AuthNetwork, useSFAKey: Bool? = nil, walletServicesConfig: WalletServicesConfig? = nil,
                mfaSettings: MfaSettings? = nil) {
        self.clientId = clientId
        self.redirectUrl = redirectUrl
        self.originData = originData
        self.authBuildEnv = authBuildEnv
        if sdkUrl != nil {
            self.sdkUrl = sdkUrl
        } else {
            self.sdkUrl = getSdkUrl(buildEnv: self.authBuildEnv)
        }
        self.storageServerUrl = storageServerUrl
        self.sessionSocketUrl = sessionSocketUrl

        self.authConnectionConfig = authConnectionConfig
        self.whiteLabel = whiteLabel
        if dashboardUrl != nil {
            self.dashboardUrl = dashboardUrl
        } else {
            self.dashboardUrl = getDashboardUrl(buildEnv: self.authBuildEnv)
        }
        self.accountAbstractionConfig = accountAbstractionConfig
        if walletSdkUrl != nil {
            self.walletSdkUrl = walletSdkUrl
        } else {
            self.walletSdkUrl = getWalletSdkUrl(buildEnv: self.authBuildEnv)
        }
        self.includeUserDataInToken = includeUserDataInToken
        self.chains = chains
        self.defaultChainId = defaultChainId
        self.enableLogging = enableLogging
        self.sessionTime = min(sessionTime, 30 * 86400) // Clamp to max 30 days
        self.web3AuthNetwork = web3AuthNetwork
        self.useSFAKey = useSFAKey
        self.walletServicesConfig = walletServicesConfig
        self.mfaSettings = mfaSettings
    }

    public init(clientId: String, web3AuthNetwork: Web3AuthNetwork, redirectUrl: String) {
        self.clientId = clientId
        self.redirectUrl = redirectUrl
        self.originData = nil
        self.authBuildEnv = BuildEnv.production
        sdkUrl = getSdkUrl(buildEnv: authBuildEnv)
        self.storageServerUrl = nil
        self.sessionSocketUrl = nil
        self.authConnectionConfig = nil
        self.whiteLabel = nil
        dashboardUrl = getDashboardUrl(buildEnv: authBuildEnv)
        self.accountAbstractionConfig = nil
        walletSdkUrl = getWalletSdkUrl(buildEnv: authBuildEnv)
        self.includeUserDataInToken = true
        self.chains = nil
        self.defaultChainId = "0x1"
        self.enableLogging = false
        self.sessionTime = 30 * 86400
        self.web3AuthNetwork = web3AuthNetwork
        self.useSFAKey = false
        self.walletServicesConfig = nil
        self.mfaSettings = nil
    }

    let clientId: String
    var redirectUrl: String
    var originData: [String: String]?
    let authBuildEnv: BuildEnv?
    var sdkUrl: String?
    var storageServerUrl: String?
    var sessionSocketUrl: String?
    var authConnectionConfig: [AuthConnectionConfig]?
    var whiteLabel: WhiteLabelData?
    var dashboardUrl: String?
    var accountAbstractionConfig: String?
    var walletSdkUrl: String?
    let includeUserDataInToken: Bool?
    var chains: [Chains]? = nil
    var defaultChainId: String? = "0x1"
    let enableLogging: Bool?
    let sessionTime: Int
    var web3AuthNetwork: Web3AuthNetwork
    var useSFAKey: Bool?
    var walletServicesConfig: WalletServicesConfig?
    let mfaSettings: MfaSettings?

    
    enum CodingKeys: String, CodingKey {
            case clientId
            case redirectUrl
            case originData
            case authBuildEnv = "buildEnv"
            case sdkUrl
            case storageServerUrl
            case sessionSocketUrl
            case authConnectionConfig
            case whiteLabel
            case dashboardUrl
            case accountAbstractionConfig
            case walletSdkUrl
            case includeUserDataInToken
            case chains
            case defaultChainId
            case enableLogging
            case sessionTime
            case web3AuthNetwork = "network"
            case useSFAKey
            case walletServicesConfig
            case mfaSettings
        }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        clientId = try values.decode(String.self, forKey: .clientId)
        redirectUrl = try values.decode(String.self, forKey: .redirectUrl)
        originData = try values.decodeIfPresent([String: String].self, forKey: .originData)
        authBuildEnv = try values.decodeIfPresent(BuildEnv.self, forKey: .authBuildEnv) ?? .production

        if let customSdkUrl = try values.decodeIfPresent(String.self, forKey: .sdkUrl) {
            sdkUrl = customSdkUrl
        } else {
            sdkUrl = getSdkUrl(buildEnv: authBuildEnv)
        }

        storageServerUrl = try values.decodeIfPresent(String.self, forKey: .storageServerUrl)
        sessionSocketUrl = try values.decodeIfPresent(String.self, forKey: .sessionSocketUrl)
        authConnectionConfig = try values.decodeIfPresent([AuthConnectionConfig].self, forKey: .authConnectionConfig)
        whiteLabel = try values.decodeIfPresent(WhiteLabelData.self, forKey: .whiteLabel)
        dashboardUrl = try values.decodeIfPresent(String.self, forKey: .dashboardUrl)
        accountAbstractionConfig = try values.decodeIfPresent(String.self, forKey: .accountAbstractionConfig)
        
        if let customWalletSdkUrl = try values.decodeIfPresent(String.self, forKey: .walletSdkUrl) {
            walletSdkUrl = customWalletSdkUrl
        } else {
            walletSdkUrl = getWalletSdkUrl(buildEnv: authBuildEnv)
        }

        includeUserDataInToken = try values.decodeIfPresent(Bool.self, forKey: .includeUserDataInToken)
        chains = try values.decodeIfPresent([Chains].self, forKey: .chains)
        defaultChainId = try values.decodeIfPresent(String.self, forKey: .defaultChainId) ?? "0x1"
        enableLogging = try values.decodeIfPresent(Bool.self, forKey: .enableLogging)
        sessionTime = try values.decodeIfPresent(Int.self, forKey: .sessionTime) ?? 30 * 86400
        web3AuthNetwork = try values.decode(Web3AuthNetwork.self, forKey: .web3AuthNetwork)
        useSFAKey = try values.decodeIfPresent(Bool.self, forKey: .useSFAKey)
        walletServicesConfig = try values.decodeIfPresent(WalletServicesConfig.self, forKey: .walletServicesConfig)
        mfaSettings = try values.decodeIfPresent(MfaSettings.self, forKey: .mfaSettings)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(clientId, forKey: .clientId)
        try container.encode(redirectUrl, forKey: .redirectUrl)
        try container.encodeIfPresent(originData, forKey: .originData)
        try container.encode(authBuildEnv, forKey: .authBuildEnv)

        // Encode sdkUrl only if it's different from the default computed value
        let defaultSdkUrl = getSdkUrl(buildEnv: authBuildEnv)
        if sdkUrl != defaultSdkUrl {
            try container.encode(sdkUrl, forKey: .sdkUrl)
        }

        try container.encodeIfPresent(storageServerUrl, forKey: .storageServerUrl)
        try container.encodeIfPresent(sessionSocketUrl, forKey: .sessionSocketUrl)
        try container.encodeIfPresent(authConnectionConfig, forKey: .authConnectionConfig)
        try container.encodeIfPresent(whiteLabel, forKey: .whiteLabel)
        try container.encodeIfPresent(dashboardUrl, forKey: .dashboardUrl)
        try container.encodeIfPresent(accountAbstractionConfig, forKey: .accountAbstractionConfig)

        let defaultWalletSdkUrl = getWalletSdkUrl(buildEnv: authBuildEnv)
        if walletSdkUrl != defaultWalletSdkUrl {
            try container.encode(walletSdkUrl, forKey: .walletSdkUrl)
        }

        try container.encodeIfPresent(includeUserDataInToken, forKey: .includeUserDataInToken)
        try container.encodeIfPresent(chains, forKey: .chains)
        try container.encodeIfPresent(defaultChainId, forKey: .defaultChainId)
        try container.encodeIfPresent(enableLogging, forKey: .enableLogging)
        try container.encode(sessionTime, forKey: .sessionTime)

        // Encode as lowercase string
        try container.encode(web3AuthNetwork.lowercaseString, forKey: .web3AuthNetwork)

        try container.encodeIfPresent(useSFAKey, forKey: .useSFAKey)
        try container.encodeIfPresent(walletServicesConfig, forKey: .walletServicesConfig)
        try container.encodeIfPresent(mfaSettings, forKey: .mfaSettings)
    }
}

public struct WalletServicesConfig: Codable {
    var confirmationStrategy: ConfirmationStrategy? = .defaultStrategy
    var whiteLabel: WhiteLabelData? = nil
}

public enum ConfirmationStrategy: String, Codable {
    case popup = "popup"
    case modal = "modal"
    case autoApprove = "auto-approve"
    case defaultStrategy = "default"

    private enum CodingKeys: String, CodingKey {
        case popup, modal
        case autoApprove = "auto-approve"
        case defaultStrategy = "default"
    }
}

public func getSdkUrl(buildEnv: BuildEnv?) -> String {
    let authServiceVersion = "v10"

    switch buildEnv {
    case .staging:
        return "https://staging-auth.web3auth.io/\(authServiceVersion)"
    case .testing:
        return "https://develop-auth.web3auth.io"
    default:
        return "https://auth.web3auth.io/\(authServiceVersion)"
    }
}

public func getWalletSdkUrl(buildEnv: BuildEnv?) -> String {
    let walletServicesVersion = "v5"
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

public func getDashboardUrl(buildEnv: BuildEnv?) -> String {
    let authDashboardVersion = "v9"
    let walletAccountConstant = "wallet/account"
    switch buildEnv {
    case .staging:
        return "https://staging-account.web3auth.io/\(authDashboardVersion)/\(walletAccountConstant)"
    case .testing:
        return "https://develop-account.web3auth.io/\(walletAccountConstant)"
    default:
        return "https://account.web3auth.io/\(authDashboardVersion)/\(walletAccountConstant)"
    }
}

public struct LoginParams: Codable {
    public init(authConnection: AuthConnection, authConnectionId: String? = nil, groupedAuthConnectionId: String? = nil, appState: String? = nil,
                mfaLevel: MFALevel? = nil, extraLoginOptions: ExtraLoginOptions? = nil, dappShare: String? = nil, curve: SUPPORTED_KEY_CURVES = .SECP256K1,
    dappUrl: String? = nil, loginHint: String? = nil, idToken: String? = nil) {
        self.authConnection = authConnection.rawValue
        self.authConnectionId = authConnectionId
        self.groupedAuthConnectionId = groupedAuthConnectionId
        self.appState = appState
        self.mfaLevel = mfaLevel
        self.extraLoginOptions = extraLoginOptions
        self.dappShare = dappShare
        self.curve = curve
        self.dappUrl = dappUrl
        self.loginHint = loginHint
        self.idToken = idToken
    }

    let authConnection: String
    let authConnectionId: String?
    let groupedAuthConnectionId: String?
    let appState: String?
    let mfaLevel: MFALevel?
    var extraLoginOptions: ExtraLoginOptions?
    var dappShare: String?
    let curve: SUPPORTED_KEY_CURVES
    let dappUrl: String?
    var loginHint: String?
    var idToken: String?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        authConnection = try values.decode(String.self, forKey: .authConnection)
        authConnectionId = try values.decode(String.self, forKey: .authConnectionId)
        groupedAuthConnectionId = try values.decode(String.self, forKey: .groupedAuthConnectionId)
        appState = try values.decodeIfPresent(String.self, forKey: .appState)
        mfaLevel = try values.decodeIfPresent(MFALevel.self, forKey: .mfaLevel)
        extraLoginOptions = try values.decodeIfPresent(ExtraLoginOptions.self, forKey: .extraLoginOptions)
        dappShare = try values.decodeIfPresent(String.self, forKey: .dappShare)
        curve = try values.decodeIfPresent(SUPPORTED_KEY_CURVES.self, forKey: .curve) ?? .SECP256K1
        dappUrl = try values.decodeIfPresent(String.self, forKey: .dappUrl)
        loginHint = try values.decodeIfPresent(String.self, forKey: .loginHint)
        idToken = try values.decodeIfPresent(String.self, forKey: .idToken)
    }
}

public struct ExtraLoginOptions: Codable {
    public init(display: String? = nil, prompt: String? = nil, max_age: String? = nil, ui_locales: String? = nil,
                id_token_hint: String? = nil, id_token: String? = nil, login_hint: String? = nil, acr_values: String? = nil, scope: String? = nil,
                audience: String? = nil, connection: String? = nil, domain: String? = nil, client_id: String? = nil, redirect_uri: String? = nil, leeway: Int? = 0, userIdField: String? = nil, isUserIdCaseSensitive: Bool? = false, additionalParams: [String: String]? = nil, access_token: String? = nil,
                flow_type: EmailFlowType = EmailFlowType.code) {
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
        self.userIdField = userIdField
        self.isUserIdCaseSensitive = isUserIdCaseSensitive
        self.additionalParams = additionalParams
        self.access_token = access_token
        self.flow_type = EmailFlowType.code
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
    let userIdField: String?
    let isUserIdCaseSensitive: Bool?
    let additionalParams: [String: String]?
    let access_token: String?
    let flow_type: EmailFlowType?
    

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
        userIdField = try values.decodeIfPresent(String.self, forKey: .userIdField)
        isUserIdCaseSensitive = try values.decodeIfPresent(Bool.self, forKey: .isUserIdCaseSensitive)
        additionalParams = try values.decodeIfPresent([String: String].self, forKey: .additionalParams)
        access_token = try values.decodeIfPresent(String.self, forKey: .access_token)
        flow_type = try values.decodeIfPresent(EmailFlowType.self, forKey: .flow_type) ?? EmailFlowType.code
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

public struct Chains: Codable {
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

public struct WalletUiConfig: Codable {
    public var enablePortfolioWidget: Bool?
    public var enableConfirmationModal: Bool?
    public var enableWalletConnect: Bool?
    public var enableTokenDisplay: Bool?
    public var enableNftDisplay: Bool?
    public var enableShowAllTokensButton: Bool?
    public var enableBuyButton: Bool?
    public var enableSendButton: Bool?
    public var enableSwapButton: Bool?
    public var enableReceiveButton: Bool?
    public var portfolioWidgetPosition: ButtonPositionType?
    public var defaultPortfolio: DefaultPortfolioType?

    public init(
        enablePortfolioWidget: Bool? = nil,
        enableConfirmationModal: Bool? = nil,
        enableWalletConnect: Bool? = nil,
        enableTokenDisplay: Bool? = nil,
        enableNftDisplay: Bool? = nil,
        enableShowAllTokensButton: Bool? = nil,
        enableBuyButton: Bool? = nil,
        enableSendButton: Bool? = nil,
        enableSwapButton: Bool? = nil,
        enableReceiveButton: Bool? = nil,
        portfolioWidgetPosition: ButtonPositionType? = nil,
        defaultPortfolio: DefaultPortfolioType? = nil
    ) {
        self.enablePortfolioWidget = enablePortfolioWidget
        self.enableConfirmationModal = enableConfirmationModal
        self.enableWalletConnect = enableWalletConnect
        self.enableTokenDisplay = enableTokenDisplay
        self.enableNftDisplay = enableNftDisplay
        self.enableShowAllTokensButton = enableShowAllTokensButton
        self.enableBuyButton = enableBuyButton
        self.enableSendButton = enableSendButton
        self.enableSwapButton = enableSwapButton
        self.enableReceiveButton = enableReceiveButton
        self.portfolioWidgetPosition = portfolioWidgetPosition
        self.defaultPortfolio = defaultPortfolio
    }
}

public enum ButtonPositionType: String, Codable {
    case bottomLeft = "bottom-left"
    case topLeft = "top-left"
    case bottomRight = "bottom-right"
    case topRight = "top-right"
}

public enum DefaultPortfolioType: String, Codable {
    case token = "token"
    case nft = "nft"
}

struct SdkUrlParams: Codable {
    var options: Web3AuthOptions
    let params: LoginParams
    let actionType: String

    enum CodingKeys: String, CodingKey {
        case options
        case params
        case actionType
    }
}

struct WalletServicesParams: Codable {
    let options: Web3AuthOptions
    let appState: String?

    enum CodingKeys: String, CodingKey {
        case options
        case appState
    }
}

struct SetUpMFAParams: Codable {
    let options: Web3AuthOptions
    let params: [String: String?]
    let actionType: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case options
        case params
        case actionType
        case sessionId
    }
}

public struct Whitelist: Codable {
    let urls: [String]
    let signedUrls: [String: String]

    enum CodingKeys: String, CodingKey {
        case urls
        case signedUrls = "signed_urls"
    }
}

public struct ProjectConfigResponse: Codable {
    public var userDataInIdToken: Bool? = true
    public var sessionTime: Int? = 86400
    public var enableKeyExport: Bool? = false
    public var whitelist: Whitelist
    public var chains: [Chains]? = nil
    public var smartAccounts: SmartAccountsConfig? = nil
    public var walletUiConfig: WalletUiConfig? = nil
    public var embeddedWalletAuth: [AuthConnectionConfig]? = nil
    public var smsOtpEnabled: Bool? = nil
    public var walletConnectEnabled: Bool? = nil
    public var walletConnectProjectId: String? = nil
    public var whitelabel: WhiteLabelData? = nil

    enum CodingKeys: String, CodingKey {
        case userDataInIdToken
        case sessionTime
        case enableKeyExport
        case whitelist
        case chains
        case smartAccounts
        case walletUiConfig
        case embeddedWalletAuth
        case smsOtpEnabled = "sms_otp_enabled"
        case walletConnectEnabled = "wallet_connect_enabled"
        case walletConnectProjectId
        case whitelabel
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userDataInIdToken = try container.decodeIfPresent(Bool.self, forKey: .userDataInIdToken) ?? true
        self.sessionTime = try container.decodeIfPresent(Int.self, forKey: .sessionTime) ?? 86400
        self.enableKeyExport = try container.decodeIfPresent(Bool.self, forKey: .enableKeyExport) ?? false
        self.whitelist = try container.decode(Whitelist.self, forKey: .whitelist)
        self.chains = try container.decodeIfPresent([Chains].self, forKey: .chains)
        self.smartAccounts = try container.decodeIfPresent(SmartAccountsConfig.self, forKey: .smartAccounts)
        self.walletUiConfig = try container.decodeIfPresent(WalletUiConfig.self, forKey: .walletUiConfig)
        self.embeddedWalletAuth = try container.decodeIfPresent([AuthConnectionConfig].self, forKey: .embeddedWalletAuth)
        self.smsOtpEnabled = try container.decodeIfPresent(Bool.self, forKey: .smsOtpEnabled) ?? false
        self.walletConnectEnabled = try container.decodeIfPresent(Bool.self, forKey: .walletConnectEnabled) ?? false
        self.walletConnectProjectId = try container.decodeIfPresent(String.self, forKey: .walletConnectProjectId)
        self.whitelabel = try container.decodeIfPresent(WhiteLabelData.self, forKey: .whitelabel)
    }
}

public struct SmartAccountsConfig: Codable {
    public var smartAccountType: SmartAccountType
    public var chains: [ChainConfig]

    enum CodingKeys: String, CodingKey {
        case smartAccountType
        case chains
    }
}

public struct ChainConfig: Codable {
    public var chainId: String
    public var bundlerConfig: BundlerConfig
    public var paymasterConfig: PaymasterConfig?

    enum CodingKeys: String, CodingKey {
        case chainId
        case bundlerConfig
        case paymasterConfig
    }
}

public struct BundlerConfig: Codable {
    public var url: String
}

public struct PaymasterConfig: Codable {
    public var url: String
}

public enum SmartAccountType: String, Codable {
    case metamask = "metamask"
    case biconomy = "biconomy"
    case kernel = "kernel"
    case safe = "safe"
    case trust = "trust"
    case light = "light"
    case simple = "simple"
    case nexus = "nexus"
}

public struct Web3AuthSubVerifierInfo: Codable {
    var verifier: String
    var idToken: String
}

