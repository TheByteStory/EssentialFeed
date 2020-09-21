//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Sharu on 21/09/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion : @escaping(HTTPClientResult) -> Void)
}
