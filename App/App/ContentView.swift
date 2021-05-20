import SwiftUI
import OpenLogin

struct ContentView: View {
    var body: some View {
        Button(action: { print("Signing in...") }, label: { Text("Sign In").padding() })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
