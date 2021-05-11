import Foundation
import UIKit
import OpenloginSwiftSdk

class Authentication: ObservableObject {
    @Published var openlogin: Openlogin
    
    init(controller: UIViewController? = nil) {
        let params = [
            "clientId":"BC01p_js5KUIjvqYYAzWlDKt6ft--5joV0TbZEKO7YbDTqnmU5v0sq_4wgkyh0QAfZZAi-v6nKD4kcxkAqPuj8U",
            "network":"mainnet",
            "redirectUrl":"openlogin://localhost"
        ]
        self.openlogin = Openlogin(controller: controller, params: params)
    }
}
