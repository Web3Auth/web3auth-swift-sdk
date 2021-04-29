//
//  File.swift
//  
//
//  Created by himanshu Chawla on 28/04/21.
//

import Foundation

public enum OpenloginError: Error {
    case invalidIframeAndNetwork
    case failedToFetchPrivateKey
    public var errorDescription: String {
        switch self {
            case .invalidIframeAndNetwork:
                return "unspecified network and iframeUrl"
            case .failedToFetchPrivateKey:
                return "Fail to fetch user's private key"
        }
    }
}
