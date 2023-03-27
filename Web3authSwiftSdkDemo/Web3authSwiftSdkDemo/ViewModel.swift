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

    func setup() async {
        guard web3Auth == nil else { return }
        await MainActor.run(body: {
            isLoading = true
            navigationTitle = "Loading"
        })
        web3Auth = await Web3Auth()
        await MainActor.run(body: {
            if self.web3Auth?.state != nil {
                user = web3Auth?.state
                loggedIn = true
            }
            isLoading = false
            navigationTitle = loggedIn ? "UserInfo" : "SignIn"
        })
    }

    func login(provider: Web3AuthProvider) {
        Task {
            do {
                let result = try await Web3Auth().login(W3ALoginParams(loginProvider: provider))
                await MainActor.run(body: {
                    user = result
                    loggedIn = true
                })

            } catch {
                print("Error")
            }
        }
    }

    func whitelabelLogin() {
        Task.detached { [unowned self] in
            do {
                web3Auth = await Web3Auth(W3AInitParams(clientId: "BKWc-6_pz5wgoZ5jvmgvbytxt7A8dvTTgsByZ87b8f-7NZW5zdhbznxT2MWJYJEv_O6MClj-g_HS4lYPJ4uQFhk", network: .testnet, whiteLabel: W3AWhiteLabelData(name: "Web3Auth Stub", dark: true, theme: ["primary": "#123456"])))
                let result = try await self.web3Auth?
                    .login(W3ALoginParams(loginProvider: .GOOGLE))
                await MainActor.run(body: {
                    user = result
                    loggedIn = true
                })
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
