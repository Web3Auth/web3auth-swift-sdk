import SwiftUI
import OpenloginSwiftSdk

@main
struct OpenloginSwiftSdkDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    Openlogin.handle(url: url)
                }
        }
    }
}
