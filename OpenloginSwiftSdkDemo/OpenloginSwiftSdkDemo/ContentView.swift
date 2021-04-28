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
                authentication.openlogin.login(loginProvider: "google")
                
            }
        }
       
    }
}

//struct CotentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
