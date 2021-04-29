//
//  File.swift
//  
//
//  Created by himanshu Chawla on 29/04/21.
//

import Foundation
import UIKit
import SafariServices


@available(iOS 11.0, *)
extension Openlogin{
    
    open class var notificationCenter: NotificationCenter {
        return NotificationCenter.default
    }
    open class var notificationQueue: OperationQueue {
        return OperationQueue.main
    }
    static let didHandleCallbackURL: Notification.Name = .init("OpenloginCallbackNotification")
    
    public func removeCallbackNotificationObserver() {
        if let observer = self.observer {
            Openlogin.notificationCenter.removeObserver(observer)
        }
    }
    
    public func observeCallback(_ block: @escaping (_ url: URL) -> Void) {
        self.observer = Openlogin.notificationCenter.addObserver(
            forName: Openlogin.didHandleCallbackURL,
            object: nil,
            queue: OperationQueue.main) { [weak self] notification in
                self?.removeCallbackNotificationObserver()
                print(notification.userInfo as Any)
                if let urlFromUserInfo = notification.userInfo?["URL"] as? URL {
                    print("executing callback block")
                    block(urlFromUserInfo)
                }else{
                    assertionFailure()
                }
        }
    }
    
    public func openURL(url: String, modalPresentationStyle: UIModalPresentationStyle) {
        
      switch self.authorizeURLHandler {
        case .external:
            let handler = ExternalURLHandler()
            handler.handle(URL(string: url)!, modalPresentationStyle: modalPresentationStyle)
        case .none:
            print("Cannot access specified browser")
        }
    }
    
    func makeUrlRequest(url: String, method: String) -> URLRequest {
        var rq = URLRequest(url: URL(string: url)!)
        rq.httpMethod = method
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.addValue("application/json", forHTTPHeaderField: "Accept")
        return rq
    }
    
    open class func handle(url: URL){
      
        let notification = Notification(name: Openlogin.didHandleCallbackURL, object: nil, userInfo: ["URL":url])
        notificationCenter.post(notification)
    }
    
    public func parseURL(url: URL) -> [String: String]{
        var responseParameters = [String: String]()
        if let query = url.query {
            responseParameters += query.parametersFromQueryString
        }
        if let fragment = url.fragment, !fragment.isEmpty {
            responseParameters += fragment.parametersFromQueryString
        }
        return responseParameters
    }
    
    // Run on main block
    static func main(block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
