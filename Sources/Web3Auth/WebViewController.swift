//
//  ViewController.swift
//  
//
//  Created by Gaurav Goel on 12/01/24.
//

import UIKit
import WebKit
  
  
class WebViewController: UIViewController {
    
    var webView : WKWebView!
    var popupWebView: WKWebView?
    let activityIndicator = UIActivityIndicatorView(style: .large)
     
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

        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.customUserAgent = "Mozilla/5.0 (Linux; Android 8.0; Pixel 2 Build/OPD3.170816.012) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Mobile Safari/537.36"
        webView.uiDelegate = self
        webView.navigationDelegate = self

        view.addSubview(webView)
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
