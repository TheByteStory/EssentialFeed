//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Sharu on 28/08/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

public enum LoadFeedResult
{
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader
{
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

