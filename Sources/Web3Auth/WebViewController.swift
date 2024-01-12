//
//  ViewController.swift
//  
//
//  Created by Gaurav Goel on 12/01/24.
//

import UIKit
import WebKit
  
  
class WebViewController: UIViewController, WebViewDelegate {
    
    var webView : WKWebView!
    let activityIndicator = UIActivityIndicatorView(style: .large)
     
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        webView = WKWebView()
        webView.navigationDelegate = self
        self.view = webView
        //webView.load(URLRequest(url: url))
        activityIndicator.stopAnimating()
        webView.allowsBackForwardNavigationGestures = true
    }
    
    func openWebViewController(url: URL) {
        webView.load(URLRequest(url: url))
        activityIndicator.stopAnimating()
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
