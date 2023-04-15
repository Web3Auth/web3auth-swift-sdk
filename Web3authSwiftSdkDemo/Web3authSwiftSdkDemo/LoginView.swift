//
//  LoginView.swift
//  Web3authSwiftSdkDemo
//
//  Created by Dhruv Jaiswal on 18/10/22.
//

import SwiftUI

struct LoginView: View {
    @StateObject var vm: ViewModel
    var body: some View {
        List {
            Button(
                action: {
                    vm.login(provider: .GOOGLE)
                },
                label: {
                    Text("Sign In with Google")
                }
            )
            
            Button(
                action: {
                    vm.loginWithGoogleCustomVerifier()
                },
                label: {
                    Text("Sign In with Google (Custom Verifier)")
                }
            )

            Button(
                action: {
                    vm.login(provider: .APPLE)
                },
                label: {
                    Text("Sign In with Apple")
                }
            )

            Button(
                action: {
                    vm.whitelabelLogin()
                },
                label: {
                    Text("Sign In with Whitelabel")
                }
            )
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(vm: ViewModel())
    }
}
