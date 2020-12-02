//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Sharu on 02/12/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

public final class CoreDataFeedStore: FeedStore {
   public init() {}

   public func retrieve(completion: @escaping RetrievalCompletion) {
       completion(.empty)
   }

   public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

   }

   public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

   }

}
