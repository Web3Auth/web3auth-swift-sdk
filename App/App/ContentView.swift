import SwiftUI
import OpenLogin

struct ContentView: View {
    var body: some View {
        Button(
            action: {
                OpenLogin
                    .webAuth()
                    .start {
                        switch $0 {
                        case .success(let credentials):
                            print("Signed in: \(credentials.privKey ?? "nil")")
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
