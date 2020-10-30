//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Sharu on 27/10/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

public enum RetrievedCachedFeedResult{
    case empty
    case found(feed:[LocalFeedImage],timestamp:Date)
    case failure(Error)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrievedCachedFeedResult) -> Void
    
    func deleteCachedFeed(completion:@escaping DeletionCompletion)

    func insert(_ feed: [LocalFeedImage],timestamp:Date, completion:@escaping InsertionCompletion)
    
    func retrieve(completion:@escaping RetrievalCompletion)

}



