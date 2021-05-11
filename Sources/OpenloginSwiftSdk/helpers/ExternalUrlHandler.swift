//
//  File.swift
//  
//
//  Created by himanshu Chawla on 28/04/21.
//

import Foundation
import UIKit


class ExternalURLHandler: OpenloginURLHandlerTypes{
    
    open func handle(_ url: URL, modalPresentationStyle: UIModalPresentationStyle) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(url)
        }
    }
}
