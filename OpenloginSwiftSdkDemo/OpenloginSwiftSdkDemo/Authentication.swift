import Foundation
import OpenloginSwiftSdk
import UIKit

class Authentication: ObservableObject {
    @Published var openlogin: Openlogin
    
    init(controller: UIViewController?) {
        print("initiailzied")
        let initParams = ["clientId":"BHD5EIewKquwKJqjktMZ6Fru5PdAz3ujIJcMDWLjCRlK655oZo5OKlc4wG6mHzdp41G1AzLgCwPueREQl7Rb5kE","network":"mainnet", "redirectUrl": "openlogin://localhost"]
        self.openlogin = Openlogin(controller: controller, params: initParams)
    }
    
    init() {
        let initParams = ["clientId":"BHD5EIewKquwKJqjktMZ6Fru5PdAz3ujIJcMDWLjCRlK655oZo5OKlc4wG6mHzdp41G1AzLgCwPueREQl7Rb5kE","network":"mainnet", "redirectUrl": "openlogin://localhost"]
        self.openlogin = Openlogin(params: initParams)
    }
}
