//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Sharu on 27/10/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion:@escaping DeletionCompletion)

    func insert(_ items: [LocalFeedItem],timestamp:Date, completion:@escaping InsertionCompletion)

}



