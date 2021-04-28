//
//  Authentication.swift
//  OpenloginSwiftSdkDemo
//
//  Created by himanshu Chawla on 28/04/21.
//

import Foundation
import OpenloginSwiftSdk

class Authentication: ObservableObject {
    @Published var openlogin: Openlogin
    @Published var isInitialized: Bool = false
    
    init() {
        print("initiailzied")
        self.openlogin = try! Openlogin(clientId: "skdk", network: .testnet, redirectUrl: "openlogin://localhost", iframeUrl: nil)
        self.isInitialized = true
    }
}
