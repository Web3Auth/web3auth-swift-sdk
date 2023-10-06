//
//  ViewModel.swift
//  Web3authSwiftSdkDemo
//
//  Created by Dhruv Jaiswal on 18/10/22.
//

import Foundation
import Web3Auth

class ViewModel: ObservableObject {
    var web3Auth: Web3Auth?
    @Published var loggedIn: Bool = false
    @Published var user: Web3AuthState?
    @Published var isLoading = false
    @Published var navigationTitle: String = ""
    @Published var privateKey: String = ""
    @Published var ed25519PrivKey: String = ""
    @Published var userInfo: Web3AuthUserInfo?
    @Published var showError: Bool = false
    var errorMessage: String = ""
    private var clientID: String = "BG4pe3aBso5SjVbpotFQGnXVHgxhgOxnqnNBKyjfEJ3izFvIVWUaMIzoCrAfYag8O6t6a6AOvdLcS4JR2sQMjR4"
    private var network: Network = .sapphire_devnet
    private var buildEnv: BuildEnv = .testing
  //  private var clientID: String = "BEaGnq-mY0ZOXk2UT1ivWUe0PZ_iJX4Vyb6MtpOp7RMBu_6ErTrATlfuK3IaFcvHJr27h6L1T4owkBH6srLphIw"
  //  private var network: Network = .mainnet
    private var useCoreKit: Bool = false

    func setup() async {
        guard web3Auth == nil else { return }
        await MainActor.run(body: {
            isLoading = true
            navigationTitle = "Loading"
        })
        web3Auth = await Web3Auth(.init(clientId: clientID, network: network, buildEnv: buildEnv, useCoreKitKey: useCoreKit))
        await MainActor.run(body: {
            if self.web3Auth?.state != nil {
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
           privateKey = web3Auth?.getPrivkey() ?? ""
           ed25519PrivKey = web3Auth?.getEd25519PrivKey() ?? ""
           userInfo = try web3Auth?.getUserInfo()
       } catch {
           errorMessage = error.localizedDescription
           showError = true

       }
    }

    func login(provider: Web3AuthProvider) {
        Task {
            do {
                web3Auth = await Web3Auth(.init(clientId: clientID, network: network, buildEnv: buildEnv, useCoreKitKey: useCoreKit))
                try await web3Auth?.login(W3ALoginParams(loginProvider: provider))
                await handleUserDetails()
            } catch {
                print("Error")
            }
        }
    }

    func loginWithGoogleCustomVerifier() {
            Task {
                do {
                    web3Auth = await Web3Auth(.init(
                        clientId: clientID,
                        network: network,
                        buildEnv: buildEnv,
                        loginConfig: [
                            "random":
                                    .init(
                                        verifier: "w3a-agg-example",
                                        typeOfLogin: .google,
                                        name: "Web3Auth-Aggregate-Verifier-Google-Example",
                                        clientId: "774338308167-q463s7kpvja16l4l0kko3nb925ikds2p.apps.googleusercontent.com",
                                        verifierSubIdentifier: "w3a-google"
                                    )
                        ]
                    )
                    )
                     try await web3Auth?.login(
                        W3ALoginParams(
                            loginProvider: "random",
                        dappShare: nil,
                        extraLoginOptions: ExtraLoginOptions(display: nil, prompt: nil, max_age: nil, ui_locales: nil, id_token_hint: nil, id_token: nil, login_hint: nil, acr_values: nil, scope: nil, audience: nil, connection: nil, domain: nil, client_id: nil, redirect_uri: nil, leeway: nil, verifierIdField: nil, isVerifierIdCaseSensitive: nil),
                        mfaLevel: .DEFAULT,
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

    func whitelabelLogin() {
        Task.detached { [unowned self] in
            do {
                web3Auth = await Web3Auth(W3AInitParams(clientId: clientID,
                                                        network: network,
                                                        buildEnv: buildEnv,
                                                        whiteLabel: W3AWhiteLabelData(appName: "Web3Auth Stub", defaultLanguage: .de, theme: ["primary": "#123456"])))
                let result = try await self.web3Auth?
                    .login(W3ALoginParams(loginProvider: .GOOGLE))
                await handleUserDetails()
            } catch let error {
                print(error)
            }
        }
    }
}

extension ViewModel {
    func showResult(result: Web3AuthState) {
        print("""
        Signed in successfully!
            Private key: \(result.privKey ?? "")
                Ed25519 Private key: \(result.ed25519PrivKey ?? "")
            User info:
                Name: \(result.userInfo?.name ?? "")
                Profile image: \(result.userInfo?.profileImage ?? "N/A")
                Type of login: \(result.userInfo?.typeOfLogin ?? "")
        """)
    }
}
