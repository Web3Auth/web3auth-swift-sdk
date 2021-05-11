import Foundation
import UIKit
import PromiseKit

@available(iOS 11.0, *)
public class Openlogin {
    let sdkUrl: URL
    var observer: NSObjectProtocol?
    var authorizeURLHandler: URLOpenerTypes?
    var controller: UIViewController?
    var initParams: [String: Any]
    var _state: [String:Any] = [:]

    public init(controller: UIViewController? = nil,browserType:URLOpenerTypes? = .sfsafari, params:[String:Any], sdkUrl:String = "https://sdk.openlogin.com") {
        self.sdkUrl =  URL(string: sdkUrl)!
        self.controller = controller
        self.authorizeURLHandler = browserType
        self.initParams = params
    }
    
    func request(method: OPENLOGIN_METHOD, params:[String:Any]) -> Promise<[String:Any]> {
        let (tempPromise, seal) = Promise<[String:Any]>.pending()

        let finalParams = ["params": params, "init": self.initParams] as [String : Any]
      
        let finalJsonParams = try! JSONSerialization.data(withJSONObject: finalParams, options: .prettyPrinted)
        
        let hashParams =  String(data: finalJsonParams, encoding: .utf8)!.toBase64String()
        
        var sdkUrlComponents = URLComponents()
        sdkUrlComponents.scheme = sdkUrl.scheme
        sdkUrlComponents.host = sdkUrl.host
        sdkUrlComponents.path = method.rawValue
        sdkUrlComponents.fragment = hashParams
        
        observeCallback{ url in
           var responseParameters = [String: String]()
           if let query = url.query,!query.isEmpty {
               responseParameters += query.parametersFromQueryString
           }
           if let fragment = url.fragment, !fragment.isEmpty {
               responseParameters += fragment.parametersFromQueryString
           }
        
           print("params received", responseParameters)
           self._state = responseParameters;
           seal.fulfill(responseParameters)
           
       }
        
        openURL(url: sdkUrlComponents.url!.absoluteString,view: controller, modalPresentationStyle: .fullScreen)
        return tempPromise
    }
    
    
    public func login(params:[String:Any]) -> Promise<[String:Any]> {
        let (tempPromise, seal) = Promise<[String:Any]>.pending()
        self.request(method: .LOGIN, params: params)
        .done{ data in
            seal.fulfill(data)
          }.catch{ err in
            seal.reject(err)
        }
       return tempPromise
    }
    
    public func logout(params:[String:Any]) -> Promise<[String:Any]> {
        let (tempPromise, seal) = Promise<[String:Any]>.pending()
        self.request(method: .LOGOUT, params: params)
        .done{ data in
            seal.fulfill(data)
          }.catch{ err in
            seal.reject(err)
        }
       return tempPromise
    }
        
}
