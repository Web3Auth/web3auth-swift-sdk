import Foundation
import UIKit
import PromiseKit

@available(iOS 11.0, *)
public class Openlogin {
    let iframeUrl: URL;
    let clientId: String;
    let redirectUrl: URL;
    public var privKey: String = "";
    var observer: NSObjectProtocol? // useful for Notifications
    var authorizeURLHandler: URLOpenerTypes?

    public init(clientId: String, network: Network, redirectUrl: String, iframeUrl: String? = nil) throws {
        self.clientId = clientId
        self.redirectUrl =  URL(string: redirectUrl)!
        if(network == .mainnet) {
            self.iframeUrl = URL(string: "https://app.openlogin.com")!
        } else if(network == .testnet) {
            self.iframeUrl = URL(string: "https://beta.openlogin.com")!
        } else if(iframeUrl != nil){
            self.iframeUrl = URL(string: iframeUrl!)!
        } else {
            throw OpenloginError.invalidIframeAndNetwork
        }
    }
    
    public func handleOpenloginCallback(callbackUrl:String) {
        let parsedUrl = URL(string: callbackUrl)
        
        var callbackUrlComponents = URLComponents()
        callbackUrlComponents.query = parsedUrl?.fragment
        for item in callbackUrlComponents.queryItems! {
            if(item.name == "result") {
                let decodedData = Data(base64Encoded: item.value!)!
                let decodedString = String(data: decodedData, encoding: .utf8)!
                let jsonData = Data(decodedString.utf8)
                do {
                    if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        self.privKey = json["privKey"] as! String
                    }
                    
                } catch {
                    print("error", error)
                    self.privKey = ""
                }
            }
        }
    }
    
    
    public func login(controller: UIViewController? = nil,loginProvider: String) -> Promise<[String:Any]> {
        let (tempPromise, seal) = Promise<[String:Any]>.pending()

        self.authorizeURLHandler = .sfsafari
        var redirectOriginComponents = URLComponents()
        redirectOriginComponents.scheme = redirectUrl.scheme
        redirectOriginComponents.host = redirectUrl.host
        redirectOriginComponents.port = redirectUrl.port
        
        let params = [
            "loginProvider": loginProvider,
            "redirectUrl":redirectUrl.absoluteString,"_clientId": clientId, "_origin": redirectOriginComponents.url!.absoluteString, "_originData":["localhost": ""]] as [String : Any]
                
        let jsonParams = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        let b64Params =  String(data: jsonParams, encoding: .utf8)!.toBase64String()
        let pid =  String.randomString(length: 32)
        var tempUrlComponents = URLComponents()
        tempUrlComponents.queryItems = [URLQueryItem(name:"b64Params", value: b64Params), URLQueryItem(name: "_pid", value:pid ), URLQueryItem(name: "_method", value: OPENLOGIN_METHOD.LOGIN.rawValue)]
        var iframeComponents = URLComponents()
        iframeComponents.scheme = iframeUrl.scheme
        iframeComponents.host = iframeUrl.host
        iframeComponents.port = iframeUrl.port
        iframeComponents.path = "/start"
        iframeComponents.fragment = tempUrlComponents.query
        
        observeCallback{ url in
           var responseParameters = [String: String]()
           if let query = url.query,!query.isEmpty {
               responseParameters += query.parametersFromQueryString
           }
           if let fragment = url.fragment, !fragment.isEmpty {
               responseParameters += fragment.parametersFromQueryString
           }
        
           print("params received", responseParameters)
         
            let result = responseParameters["result"]
            let decodedData = Data(base64Encoded: result!)!
            let decodedString = String(data: decodedData, encoding: .utf8)!
            let jsonData = Data(decodedString.utf8)
            do {
                if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    self.privKey = json["privKey"] as! String
                    seal.fulfill(["privKey": self.privKey])
                } else {
                    seal.reject(OpenloginError.failedToFetchPrivateKey)
                }
                
            } catch {
                print("error", error)
                self.privKey = ""
                seal.reject(error)
            }
            print("self priv", self.privKey)

       }
        
        openURL(url: iframeComponents.url!.absoluteString,view: controller, modalPresentationStyle: .fullScreen)
       return tempPromise
    }
        
}
