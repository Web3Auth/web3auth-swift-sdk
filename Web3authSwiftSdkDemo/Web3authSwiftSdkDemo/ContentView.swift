import SwiftUI
import Web3Auth

struct ContentView: View {
    @SwiftUI.State var text = ""
    @State var loggedIn = false
    var body: some View {
        VStack {
            if loggedIn {
                HStack {
                    Spacer()
                    Button {
                        Task.detached {
                            try await Web3Auth().logout()
                            loggedIn.toggle()
                        }
                    } label: {
                        Text("Logout")
                    }
                    .padding()
                }
            }
            Spacer()
            VStack {
                Button(
                    action: {
                        Task.detached {
                            do {
                                let result = try await Web3Auth().login(W3ALoginParams())
                                loggedIn = true
                                showResult(result: result)
                            } catch {
                                print("Error")
                            }
                        }

                    },
                    label: {
                        Text("Sign In")
                            .padding()
                    }
                )

                Button(
                    action: {
                        Task {
                            Task.detached {
                                do {
                                    let result = try await Web3Auth().login(W3ALoginParams(loginProvider: .GOOGLE))
                                    loggedIn = true
                                    showResult(result: result)
                                } catch {
                                    print("Error")
                                }
                            }
                        }
                    },
                    label: {
                        Text("Sign In with Google")
                            .padding()
                    }
                )

                Button(
                    action: {
                        Task {
                            Task.detached {
                                do {
                                    let result = try await Web3Auth().login(W3ALoginParams())
                                    loggedIn = true
                                    showResult(result: result)
                                } catch {
                                    print("Error")
                                }
                            }
                        }
                    },
                    label: {
                        Text("Sign In with Apple")
                            .padding()
                    }
                )

                Button(
                    action: {
                        Task {
                            do {
                                let result = try await Web3Auth(W3AInitParams(clientId: "BJYIrHuzluClBK0vvTBUJ7kQylV_Dj3NA-X1q4Qvxs2Ay3DySkacOpoOb83lDTHJRVY83bFlYtt4p8pQR-oCYtw", network: .testnet, whiteLabel: W3AWhiteLabelData(name: "Web3Auth Stub", dark: true, theme: ["primary": "#123456"])))
                                    .login(W3ALoginParams(loginProvider: .GOOGLE))
                                showResult(result: result)
                            } catch let error {
                                print(error)
                            }
                        }
                    },
                    label: {
                        Text("Sign In with Whitelabel")
                            .padding()
                    }
                )

                Text(text).foregroundColor(.white)
            }
            Spacer()
        }
    }

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
        text = """
        Signed in successfully!
            Private key: \(result.privKey ?? "")
                Ed25519 Private key: \(result.ed25519PrivKey ?? "")
            User info:
                Name: \(result.userInfo?.name ?? "")
                Profile image: \(result.userInfo?.profileImage ?? "N/A")
                Type of login: \(result.userInfo?.typeOfLogin ?? "")
        """
    }
}

struct NewContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
