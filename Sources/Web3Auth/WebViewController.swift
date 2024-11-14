//
//  ViewController.swift
//  
//
//  Created by Gaurav Goel on 12/01/24.
//

import UIKit
import WebKit
  
  
class WebViewController: UIViewController, WKScriptMessageHandler {
    
    var webView : WKWebView!
    var popupWebView: WKWebView?
    let activityIndicator = UIActivityIndicatorView(style: .large)
    var redirectUrl: String?
    var onSignResponse: (SignResponse) -> Void
    var onSessionResponse: (SessionResponse) -> Void
    var methodType: Int
    
    init(redirectUrl: String? = nil, methodType: Int = 0,onSignResponse: @escaping (SignResponse) -> Void, onSessionResponse: @escaping (SessionResponse) -> Void) {
        self.redirectUrl = redirectUrl
        self.methodType = methodType
        self.onSignResponse = onSignResponse
        self.onSessionResponse = onSessionResponse
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.methodType = 0
        self.onSignResponse = { _ in }
        self.onSessionResponse = { _ in }
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        activityIndicator.startAnimating()
        activityIndicator.stopAnimating()
    }
    
    func setupWebView() {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController.add(self, name: "JSBridge")
        configuration.applicationNameForUserAgent = "Version/8.0.2 Safari/600.2.5"

        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.uiDelegate = self
        webView.navigationDelegate = self

        view.addSubview(webView)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let redirectUrl = redirectUrl, !redirectUrl.isEmpty {
                if let url = navigationAction.request.url, url.absoluteString.contains(redirectUrl) {
                    let host = url.host ?? ""
                    let fragment = url.fragment ?? ""
                    let component = URLComponents.init(string: host + "?" + fragment)
                    let queryItems = component?.queryItems
                    let b64ParamsItem = queryItems?.first(where: { $0.name == "b64Params" })
                    let callbackFragment = (b64ParamsItem?.value)!
                    let b64ParamString = Data.fromBase64URL(callbackFragment)
                    if(methodType == 0) {
                        let sessionResponse = try? JSONDecoder().decode(SessionResponse.self, from: b64ParamString!)
                        onSessionResponse(sessionResponse!)
                    } else {
                        let signResponse = try? JSONDecoder().decode(SignResponse.self, from: b64ParamString!)
                        onSignResponse(signResponse!)
                    }
                    dismiss(animated: true, completion: nil)
                }
            }
            decisionHandler(.allow)
        }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "JSBridge", let messageBody = message.body as? String {
            switch messageBody {
            case "closeWalletServices":
                dismiss(animated: true, completion: nil)
            default:
                return
            }
        }
    }
}
  
  
extension WebViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}

extension WebViewController: WKUIDelegate {
func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    popupWebView = WKWebView(frame: view.bounds, configuration: configuration)
    popupWebView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    popupWebView!.navigationDelegate = self
    popupWebView!.uiDelegate = self
    view.addSubview(popupWebView!)
    return popupWebView!
}

func webViewDidClose(_ webView: WKWebView) {
    if webView == popupWebView {
        popupWebView?.removeFromSuperview()
        popupWebView = nil
    }
}
    
}
