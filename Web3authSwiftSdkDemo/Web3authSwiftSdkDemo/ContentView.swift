//
//  ContentView.swift
//  Web3AuthPodSample
//
//  Created by Dhruv Jaiswal on 03/10/22.
//

import SwiftUI
import Web3Auth

struct ContentView: View {
    @SwiftUI.State var text = ""
    @State var loggedIn = false
    @State var user:Web3AuthState?
    var body: some View {
        NavigationView{
            VStack{
                if loggedIn{
                    LoggedInView(user: user, loggedIn: $loggedIn)
                }
                else{
                    List {
                        Button(
                            action: {
                                Task {
                                    await Web3Auth()
                                        .login(W3ALoginParams()) {
                                            switch $0 {
                                            case let .success(result):
                                                showResult(result: result)
                                                user = result
                                                self.user = result
                                                loggedIn.toggle()
                                            case let .failure(error):
                                                print("Error: \(error)")
                                            }
                                        }
                                }
                            },
                            label: {
                                Text("Sign In")
                            }
                        )
                        
                        Button(
                            action: {
                                Task {
                                    await Web3Auth()
                                        .login(W3ALoginParams(loginProvider: .GOOGLE)) {
                                            switch $0 {
                                            case let .success(result):
                                                showResult(result: result)
                                                
                                                
                                                user = result
                                                loggedIn.toggle()
                                                
                                            case let .failure(error):
                                                print("Error: \(error)")
                                            }
                                        }
                                }
                            },
                            label: {
                                Text("Sign In with Google")
                            }
                        )
                        
                        
                        
                        Button(
                            action: {
                                Task {
                                    await Web3Auth()
                                        .login(W3ALoginParams(loginProvider: .APPLE)) {
                                            switch $0 {
                                            case let .success(result):
                                                showResult(result: result)
                                                user = result
                                                loggedIn.toggle()
                                            case let .failure(error):
                                                print("Error: \(error)")
                                            }
                                        }
                                }
                            },
                            label: {
                                Text("Sign In with Apple")
                            }
                        )
                        
                        Button(
                            action: {
                                Task {
                                    await Web3Auth(W3AInitParams(clientId: "BJYIrHuzluClBK0vvTBUJ7kQylV_Dj3NA-X1q4Qvxs2Ay3DySkacOpoOb83lDTHJRVY83bFlYtt4p8pQR-oCYtw", network: .testnet, whiteLabel: W3AWhiteLabelData(name: "Web3Auth Stub", dark: true, theme: ["primary": "#123456"])))
                                        .login(W3ALoginParams(loginProvider: .GOOGLE)) {
                                            switch $0 {
                                            case let .success(result):
                                                showResult(result: result)
                                                user = result
                                                loggedIn.toggle()
                                            case let .failure(error):
                                                print("Error: \(error)")
                                            }
                                        }
                                }
                            },
                            label: {
                                Text("Sign In with Whitelabel")
                            }
                        )
                    }
                    .listStyle(.automatic)
                }
            }
                .navigationTitle(loggedIn ? "UserInfo" : "SignIn")
                Spacer()
            }
        }

    func showResult(result: Web3AuthState) {
        print("""
        Signed in successfully!
            Private key: \(result.privKey)
            Ed25519 Private key: \(result.ed25519PrivKey)
            User info:
                Name: \(result.userInfo?.name)
                Profile image: \(result.userInfo?.profileImage ?? "N/A")
                Type of login: \(result.userInfo?.typeOfLogin)
        """)
        text = """
        Signed in successfully!
            Private key: \(result.privKey)
            Ed25519 Private key: \(result.ed25519PrivKey)
            User info:
                Name: \(result.userInfo?.name)
                Profile image: \(result.userInfo?.profileImage ?? "N/A")
                Type of login: \(result.userInfo?.typeOfLogin)
        """
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

