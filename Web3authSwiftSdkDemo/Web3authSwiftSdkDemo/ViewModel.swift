import Foundation
import web3
import Web3Auth

class ViewModel: ObservableObject {
    var web3Auth: Web3Auth?
    @Published var loggedIn: Bool = false
    @Published var user: Web3AuthResponse?
    @Published var isLoading = false
    @Published var navigationTitle: String = ""
    @Published var privateKey: String = ""
    @Published var ed25519PrivKey: String = ""
    @Published var userInfo: Web3AuthUserInfo?
    @Published var showError: Bool = false
    var errorMessage: String = ""
    private var clientID: String = "BPi5PB_UiIZ-cPz1GtV5i1I2iOSOHuimiXBI0e-Oe_u6X3oVAbCiAZOTEBtTXw4tsluTITPqA8zMsfxIKMjiqNQ"
    private var redirectUrl: String = "com.web3auth.sdkapp://auth"
    private var web3AuthNetwork: Web3AuthNetwork = .sapphire_mainnet
    private var buildEnv: BuildEnv = .testing
    //  private var clientID: String = "BEaGnq-mY0ZOXk2UT1ivWUe0PZ_iJX4Vyb6MtpOp7RMBu_6ErTrATlfuK3IaFcvHJr27h6L1T4owkBH6srLphIw"
    //  private var network: Web3AuthNetwork = .mainnet
    private var useCoreKit: Bool = false
    private var chainConfig: [Chains] = [
        Chains(
            chainNamespace: .eip155,
            chainId: "0x1",
            rpcTarget: "https://mainnet.infura.io/v3/79921cf5a1f149f7af0a0fef80cf3363",
            ticker: "ETH"
        )
    ]
    private var authConnectionConfig: [AuthConnectionConfig] = [
        AuthConnectionConfig(
            authConnectionId: "web3auth-auth0-email-passwordless-sapphire-devnet",
            authConnection: .CUSTOM,
            clientId: "d84f6xvbdV75VTGmHiMWfZLeSPk8M07C"
        )
    ]

    func setup() async throws {
        guard web3Auth == nil else { return }
        var authConfig: [AuthConnectionConfig] = []

        authConfig.append(
            AuthConnectionConfig(
                authConnectionId: "w3ads",
                authConnection: .GOOGLE,
                clientId: "519228911939-snh959gvvmjieoo4j14kkaancbkjp34r.apps.googleusercontent.com",
                groupedAuthConnectionId: "aggregate-mobile"
            )
        )

        authConfig.append(
            AuthConnectionConfig(
                authConnectionId: "auth0-test",
                authConnection: .CUSTOM,
                clientId: "hUVVf4SEsZT7syOiL0gLU9hFEtm2gQ6O",
                groupedAuthConnectionId: "aggregate-mobile"
            )
        )
        await MainActor.run(body: {
            isLoading = true
            navigationTitle = "Loading"
        })
        web3Auth = try await Web3Auth(.init(clientId: clientID, redirectUrl: "com.web3auth.sdkapp://auth", authBuildEnv: buildEnv, authConnectionConfig: authConfig,                                           web3AuthNetwork: web3AuthNetwork,
                                            // sdkUrl: URL(string: "https://auth.mocaverse.xyz"),
                                            // walletSdkUrl: URL(string: "https://lrc-mocaverse.web3auth.io"),
                                            useSFAKey: useCoreKit))
        await MainActor.run(body: {
            if self.web3Auth?.web3AuthResponse != nil {
                handleUserDetails()
                loggedIn = true
            }
            isLoading = false
            navigationTitle = loggedIn ? "UserInfo" : "SignIn"
        })
    }

    @MainActor func handleUserDetails() {
        do {
            loggedIn = true
            privateKey = ((web3Auth?.getPrivateKey() != "") ? web3Auth?.getPrivateKey() : try web3Auth?.getWeb3AuthResponse().factorKey) ?? ""
            ed25519PrivKey = web3Auth?.getEd25519PrivateKey() ?? ""
            userInfo = try web3Auth?.getUserInfo()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func login(authConnection: AuthConnection) {
        Task {
            do {
                _ = try await web3Auth?.login(LoginParams(authConnection: authConnection,
                                                          mfaLevel: .DEFAULT, extraLoginOptions: ExtraLoginOptions(display: nil, prompt: nil, max_age: nil, ui_locales: nil, id_token_hint: nil, id_token: nil, login_hint: "hello@tor.us", acr_values: nil, scope: nil, audience: nil, connection: nil, domain: nil, client_id: nil, redirect_uri: nil, leeway: nil, userIdField: nil, isUserIdCaseSensitive: nil, additionalParams: nil),
                                                             curve: .SECP256K1
                    ))
                await handleUserDetails()
            } catch {
                print("Error")
            }
        }
    }

    func loginWithGoogle(authConnection: AuthConnection) {
        Task {
            do {
                var authConfig: [AuthConnectionConfig] = []

                authConfig.append(
                    AuthConnectionConfig(
                        authConnectionId: "w3ads",
                        authConnection: .GOOGLE,
                        clientId: "519228911939-snh959gvvmjieoo4j14kkaancbkjp34r.apps.googleusercontent.com",
                        groupedAuthConnectionId: "aggregate-mobile"
                    )
                )

                authConfig.append(
                    AuthConnectionConfig(
                        authConnectionId: "auth0-test",
                        authConnection: .CUSTOM,
                        clientId: "hUVVf4SEsZT7syOiL0gLU9hFEtm2gQ6O",
                        groupedAuthConnectionId: "aggregate-mobile"
                    )
                )
                web3Auth = try await Web3Auth(.init(
                    clientId: clientID,
                    redirectUrl: redirectUrl, authBuildEnv: buildEnv, authConnectionConfig: authConfig, web3AuthNetwork: web3AuthNetwork,
                    useSFAKey: useCoreKit
                ))
                _ = try await web3Auth?.login(LoginParams(authConnection: .GOOGLE,
                                                          authConnectionId: "w3ads",
                                                          groupedAuthConnectionId: "aggregate-mobile",
                                                          mfaLevel: .DEFAULT, extraLoginOptions: ExtraLoginOptions(display: nil, prompt: nil, max_age: nil, ui_locales: nil, id_token_hint: nil, id_token: nil, login_hint: nil, acr_values: nil, scope: nil, audience: nil, connection: nil, domain: "https://web3auth.au.auth0.com/", client_id: nil, redirect_uri: nil, leeway: nil, userIdField: "email", isUserIdCaseSensitive: false, additionalParams: nil),
                                                             curve: .SECP256K1
                    ))
                await handleUserDetails()
            } catch {
                print("Error")
            }
        }
    }

    func loginWithGoogleCustomVerifier() {
        Task {
            do {
                web3Auth = try await Web3Auth(.init(
                    clientId: clientID,
                    redirectUrl: redirectUrl, authBuildEnv: buildEnv, authConnectionConfig: [
                        AuthConnectionConfig(
                            authConnectionId: "w3a-agg-example",
                            authConnection: .GOOGLE,
                            name: "Web3Auth-Aggregate-Verifier-Google-Example",
                            clientId: "774338308167-q463s7kpvja16l4l0kko3nb925ikds2p.apps.googleusercontent.com",
                            groupedAuthConnectionId: "w3a-google"
                        )
                    ], web3AuthNetwork: web3AuthNetwork
                )
                )
                _ = try await web3Auth?.login(
                    LoginParams(
                        authConnection: .GOOGLE,
                        mfaLevel: .DEFAULT, extraLoginOptions: ExtraLoginOptions(display: nil, prompt: nil, max_age: nil, ui_locales: nil, id_token_hint: nil, id_token: nil, login_hint: nil, acr_values: nil, scope: nil, audience: nil, connection: nil, domain: nil, client_id: nil, redirect_uri: nil, leeway: nil, userIdField: nil, isUserIdCaseSensitive: nil, additionalParams: nil), dappShare: nil,
                        curve: .SECP256K1
                    ))
                await handleUserDetails()
            } catch {
                print("Error")
            }
        }
    }

    @MainActor func logout() {
        Task {
            do {
                try await web3Auth?.logout()
                loggedIn = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    @MainActor func launchWalletServices() {
        Task {
            do {
                try await web3Auth?.showWalletUI()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    @MainActor func enableMFA() {
        Task {
            do {
                /*
                web3Auth = try await Web3Auth(Web3AuthOptions(clientId: clientID,
                                                web3AuthNetwork: web3AuthNetwork,
                                                            buildEnv: buildEnv,
                                                            redirectUrl: redirectUrl,
                                                            whiteLabel: W3AWhiteLabelData(appName: "Web3Auth Stub", defaultLanguage: .en, mode: .dark, theme: ["primary": "#123456"])))
                 */
                _ = try await self.web3Auth?.enableMFA()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    @MainActor func manageMFA() {
        Task {
            do {
                _ = try await self.web3Auth?.manageMFA()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    @MainActor func request() {
        Task {
            do {
                let key = self.web3Auth!.getPrivateKey()
                let pk = try KeyUtil.generatePublicKey(from: Data(hexString: key) ?? Data())
                let pkAddress = KeyUtil.generateAddress(from: pk).asString()
                let checksumAddress = EthereumAddress(pkAddress).toChecksumAddress()
                var params = [Any]()
                params.append("Hello, Web3Auth from Android!")
                params.append(checksumAddress)
                params.append("Web3Auth")
                let signResponse = try await self.web3Auth?.request(method: "personal_sign", requestParams: params)
                if let response = signResponse {
                    print("Sign response received: \(response)")
                } else {
                    print("No sign response received.")
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    func whitelabelLogin() {
        Task.detached { [unowned self] in
            do {
                web3Auth = try await Web3Auth(
                    Web3AuthOptions(
                        clientId: clientID,
                        redirectUrl: redirectUrl, authBuildEnv: buildEnv, authConnectionConfig: [
                            AuthConnectionConfig(
                                authConnectionId: "web3auth-auth0-email-passwordless-sapphire-devnet",
                                authConnection: .CUSTOM,
                                clientId: "d84f6xvbdV75VTGmHiMWfZLeSPk8M07C"
                            )
                        ], web3AuthNetwork: web3AuthNetwork
                        ))
                _ = try await self.web3Auth?
                    .login(LoginParams(authConnection: .GOOGLE))
                await handleUserDetails()
            } catch let error {
                print(error)
            }
        }
    }
}

extension ViewModel {
    func showResult(result: Web3AuthResponse) {
        print("""
        Signed in successfully!
            Private key: \(result.privateKey ?? "")
                Ed25519 Private key: \(result.ed25519PrivateKey ?? "")
            User info:
                Name: \(result.userInfo?.name ?? "")
                Profile image: \(result.userInfo?.profileImage ?? "N/A")
                AuthConnection: \(result.userInfo?.authConnection ?? "")
        """)
    }
}
