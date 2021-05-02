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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("redirectUrl", url)
                    Openlogin.handle(url: url)
                    
                }
            
        }
    }
}
