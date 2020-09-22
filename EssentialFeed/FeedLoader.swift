//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Sharu on 28/08/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

public enum LoadFeedResult<Error:Swift.Error>
{
    case success([FeedItem])
    case failure(Error)
}

extension LoadFeedResult: Equatable where Error:Equatable{}

protocol FeedLoader
{
    associatedtype Error : Swift.Error
    func load(completion: @escaping (LoadFeedResult<Error>) -> Void)
}

