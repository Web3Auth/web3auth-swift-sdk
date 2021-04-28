//
//  File.swift
//  
//
//  Created by himanshu Chawla on 28/04/21.
//

import Foundation
import UIKit

public protocol TorusURLHandlerTypes{
    func handle(_ url: URL, modalPresentationStyle: UIModalPresentationStyle)
}

public enum URLOpenerTypes : String{
    case external = "external"
    case sfsafari = "sfsafari"
}
