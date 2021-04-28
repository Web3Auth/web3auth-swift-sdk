//
//  File.swift
//  
//
//  Created by himanshu Chawla on 28/04/21.
//

import Foundation

public enum OpenloginError: Error {
    case invalidIframeAndNetwork
    public var errorDescription: String {
        switch self {
            case .invalidIframeAndNetwork:
                return "unspecified network and iframeUrl"
        }
    }
}
