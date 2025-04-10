import SwiftUI

struct LoginView: View {
    @StateObject var vm: ViewModel
    var body: some View {
        List {
            Button(
                action: {
                    vm.login(authConnection: .EMAIL_PASSWORDLESS)
                },
                label: {
                    Text("Sign In with Email Passwordless")
                }
            )
            Button(
                action: {
                    vm.loginWithGoogle(authConnection: .GOOGLE)
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
                    vm.login(authConnection: .APPLE)
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
        .alert(isPresented: $vm.showError) {
            Alert(title: Text("Error"), message: Text(vm.errorMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(vm: ViewModel())
    }
}
