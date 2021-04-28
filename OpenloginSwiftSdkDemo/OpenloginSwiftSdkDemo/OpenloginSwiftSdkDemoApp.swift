//
//  OpenloginSwiftSdkDemoApp.swift
//  OpenloginSwiftSdkDemo
//
//  Created by himanshu Chawla on 27/04/21.
//

import SwiftUI
import OpenloginSwiftSdk

@main
struct OpenloginSwiftSdkDemoApp: App {
   
    var authenticationObj: Authentication
    init() {
        authenticationObj = Authentication()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationObj)
                .onOpenURL { url in
                    print("redirectUrl", url)
                    authenticationObj.openlogin.handleOpenloginCallback(callbackUrl: url.absoluteString)
                    
                }
            
        }
    }
}
