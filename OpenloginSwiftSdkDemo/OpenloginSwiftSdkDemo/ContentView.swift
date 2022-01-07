import SwiftUI
import OpenLogin


struct ContentView: View {
    @SwiftUI.State var text = ""
    var body: some View {
        VStack {
            Button(
                action: {
                    OpenLogin
                        .webAuth()
                        .login() {
                            switch $0 {
                            case .success(let result):
                                    showResult(result: result)
                            case .failure(let error):
                                print("Error: \(error)")
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
                    OpenLogin
                        .webAuth()
                        .login(provider: .GOOGLE) {
                            switch $0 {
                            case .success(let result):
                                showResult(result: result)
                            case .failure(let error):
                                print("Error: \(error)")
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
                    OpenLogin
                        .webAuth()
                        .login(provider: .APPLE) {
                            switch $0 {
                            case .success(let result):
                                showResult(result: result)
                            case .failure(let error):
                                print("Error: \(error)")
                            }
                        }
                },
                label: {
                    Text("Sign In with Apple")
                        .padding()
                }
            )
            
 
            
            Text(text).foregroundColor(.white)
            
        }
        
    }
    
    func showResult(result: OpenLogin.OpenLoginState){
        print("""
            Signed in successfully!
                Private key: \(result.privKey)
                User info:
                    Name: \(result.userInfo.name)
                    Profile image: \(result.userInfo.profileImage ?? "N/A")
                    Type of login: \(result.userInfo.typeOfLogin)
            """)
        text = """
            Signed in successfully!
                Private key: \(result.privKey)
                User info:
                    Name: \(result.userInfo.name)
                    Profile image: \(result.userInfo.profileImage ?? "N/A")
                    Type of login: \(result.userInfo.typeOfLogin)
            """
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
