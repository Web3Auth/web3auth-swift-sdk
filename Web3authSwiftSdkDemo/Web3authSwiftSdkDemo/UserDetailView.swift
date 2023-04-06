//
//  LoggedInView.swift
//  Web3AuthPodSample
//
//  Created by Dhruv Jaiswal on 10/10/22.
//

import SwiftUI

struct UserDetailView: View {
    @ObservedObject var vm:ViewModel
    @State private var showingAlert = false

    var body: some View {
        if vm.loggedIn {
            List {
                Section {
                    Text("\(vm.privateKey)")
                } header: {
                    Text("Private key")
                }
                Section {
                    Text("\(vm.ed25519PrivKey)")
                }
                header: {
                    Text("ED25519 Key")
                }
                Section {
                    Text("Name \( vm.userInfo?.name ?? "")")
                    Text("Email \(vm.userInfo?.email ?? "")")
                }
                header: {
                    Text("User Info")
                }
                Section {
                    Button {
                        vm.logout()
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
        UserDetailView(vm: .init())
    }
}
