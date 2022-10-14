//
//  LoggedInView.swift
//  Web3AuthPodSample
//
//  Created by Dhruv Jaiswal on 10/10/22.
//

import SwiftUI
import Web3Auth

struct LoggedInView: View {
    @State var user:Web3AuthState?
    @Binding var loggedIn:Bool
    @State private var showingAlert = false
    var body: some View {
            if let user = user{
                List {
                    Section {
                        Text("\(user.privKey)")
                    }header: {
                        Text("Private key")
                    }
                    Section{
                        Text("\(user.ed25519PrivKey)")
                    }
                header: {
                    Text("ED25519 Key")
                }
                    Section {
                        Text("Name \(user.userInfo.name)")
                        Text("Email \(user.userInfo.email ?? "")")
                    }
                header: {
                    Text("User Info")
                }
                    Section{
                        Button {
                            
                            Task {
                                do{
                                    try await Web3Auth().logout()
                                    loggedIn.toggle()
                                }
                                catch{
                                    showingAlert = true
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
           
            
        }
    }
}

struct LoggedInView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInView(user: nil, loggedIn: .constant(true))
    }
}

