import SwiftUI
import OpenLogin


struct ContentView: View {
    @SwiftUI.State var text = ""
    var body: some View {
        VStack {
            Button(
                action: {
                    OpenLogin()
                        .login(OLLoginParams()) {
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
                    OpenLogin()
                        .login(OLLoginParams(loginProvider: .GOOGLE)) {
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
                    OpenLogin()
                        .login(OLLoginParams(loginProvider: .APPLE)) {
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
            
            Button(
                action: {
                    OpenLogin(OLInitParams(clientId: "BJYIrHuzluClBK0vvTBUJ7kQylV_Dj3NA-X1q4Qvxs2Ay3DySkacOpoOb83lDTHJRVY83bFlYtt4p8pQR-oCYtw", network: .testnet, whiteLabel: OLWhiteLabelData(name: "Web3Auth Stub", dark: true, theme: ["primary": "#123456"])))
                        .login(OLLoginParams(loginProvider: .GOOGLE)) {
                            switch $0 {
                            case .success(let result):
                                showResult(result: result)
                            case .failure(let error):
                                print("Error: \(error)")
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
        
    }
    
    func showResult(result: OpenLoginState){
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
