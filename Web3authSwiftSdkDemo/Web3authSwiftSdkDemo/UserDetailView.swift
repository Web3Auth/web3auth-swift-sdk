//
//  LoggedInView.swift
//  Web3AuthPodSample
//
//  Created by Dhruv Jaiswal on 10/10/22.
//

import SwiftUI
import Web3Auth

struct UserDetailView: View {
    @State var user: Web3AuthState?
    @Binding var loggedIn: Bool
    @State private var showingAlert = false

    var body: some View {
        if let user = user {
            List {
                Section {
                    Text("\(user.privKey ?? "")")
                } header: {
                    Text("Private key")
                }
                Section {
                    Text("\(user.ed25519PrivKey ?? "")")
                }
                header: {
                    Text("ED25519 Key")
                }
                Section {
                    Text("Name \(user.userInfo?.name ?? "")")
                    Text("Email \(user.userInfo?.email ?? "")")
                }
                header: {
                    Text("User Info")
                }
                Section {
                    Button {
                        Task.detached {
                            do {
                                try await Web3Auth().logout()
                                loggedIn.toggle()
                            } catch {
                                DispatchQueue.main.async {
                                    showingAlert = true
                                }
                            }
                        }
                    } label: {
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("Error"), message: Text("Logout failed!"), dismissButton: .default(Text("OK")))
                    }
                }
            }
            .listStyle(.automatic)
        }
    }
}

struct UserDetailView_Previews: PreviewProvider {
    static var previews: some View {
        UserDetailView(user: .init(privKey: "12345", ed25519PrivKey: "32334", sessionId: "23234384y7735y47shdj", userInfo: nil, error: nil, coreKitKey: "345264", coreKitEd25519PrivKey: "64534576"), loggedIn: .constant(true))
    }
}
