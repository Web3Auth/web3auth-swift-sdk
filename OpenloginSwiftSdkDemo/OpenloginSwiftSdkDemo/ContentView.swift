//
//  ContentView.swift
//  OpenloginSwiftSdkDemo
//
//  Created by himanshu Chawla on 27/04/21.
//

import SwiftUI
 import OpenloginSwiftSdk
struct ContentView: View {
    @EnvironmentObject var authentication: Authentication

    var body: some View {
        VStack {
            Button("Login with google") {
                print("hello")
                authentication.openlogin.login(loginProvider: "google").done{ data in
                    print("private key rebuild", data)
                }.catch{ err in
                    print(err)
                }
                
            }
        }
       
    }
}

//struct CotentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
