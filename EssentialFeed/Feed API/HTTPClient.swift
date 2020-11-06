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

/// The completion handler can be invoked in any thread.
/// Clients are reponsible to dispatch to appropriate threads, if needed.
public protocol HTTPClient {
    func get(from url: URL, completion : @escaping(HTTPClientResult) -> Void)
}
