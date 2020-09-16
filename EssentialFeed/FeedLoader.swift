//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Sharu on 28/08/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

enum LoadFeedResult
{
    case success([FeedItem])
    case error(Error)
}
protocol FeedLoader
{
    
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

