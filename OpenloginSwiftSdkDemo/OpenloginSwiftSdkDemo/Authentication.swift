//
//  Authentication.swift
//  OpenloginSwiftSdkDemo
//
//  Created by himanshu Chawla on 28/04/21.
//

import Foundation
import OpenloginSwiftSdk
import UIKit
class Authentication: ObservableObject {
    @Published var openlogin: Openlogin
    
    init(controller: UIViewController?) {
        print("initiailzied")
        let initParams = ["clientId":"","network":"testnet", "redirectUrl": "openlogin://localhost"]
        self.openlogin = Openlogin(controller: controller, params: initParams)
    }
    init() {
        let initParams = ["clientId":"","network":"testnet", "redirectUrl": "openlogin://localhost"]
        self.openlogin = Openlogin(params: initParams)
    }
}
