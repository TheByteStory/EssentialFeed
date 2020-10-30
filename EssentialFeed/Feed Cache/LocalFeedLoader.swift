//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Sharu on 27/10/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

public final class LocalFeedLoader
{
    private let store:FeedStore
    private let currentDate : () -> Date
    private let calendar = Calendar(identifier: .gregorian)

    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    public init(store:FeedStore, currentDate:@escaping() -> Date){
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed:[FeedImage], completion:@escaping (SaveResult) -> Void)
    {
            store.deleteCachedFeed{[weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error
            {
                completion(cacheDeletionError)
            }
            else
            {
                self.cache(feed, with:completion)
            }
            }
            
    }
    
    public func load(completion:@escaping(LoadResult) -> Void)
    {
        store.retrieve { [weak self] result in
        guard let self = self else { return }
            switch result{
            case let .failure(error):
                completion(.failure(error))
            case let .found(feed,timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))
            case .found:
                 completion(.success([]))
            case .empty:
                completion(.success([]))
            }
           
            
        }
    }
    
    public func validateCache()
    {
        store.retrieve{ [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                self.store.deleteCachedFeed{ _ in }
            case let .found(_, timestamp) where !self.validate(timestamp):
                self.store.deleteCachedFeed{ _ in }
                
            case .empty, .found: break
            }
        }
    }
    
    private var maxCacheAgeInDays : Int
    {
        return 7
    }
    
    private func validate(_ timestamp:Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp)
            else{
        return false
    }
        return currentDate() < maxCacheAge
    }
    
    
    
    private func cache(_ feed: [FeedImage], with completion: @escaping(SaveResult) -> Void)
    {
        self.store.insert(feed.toLocal(), timestamp:self.currentDate()){[weak self] error in
        guard self != nil else { return }
        completion(error)
    
        }
    }
    
}

//Mapping LocalFeedItem with FeedItem
private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage]{
        return map {
            
            LocalFeedImage(id:$0.id, description:$0.description, location:$0.location, imageURL:$0.url)
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage]{
        return map {
            
            FeedImage(id:$0.id, description:$0.description, location:$0.location, url:$0.url)
        }
    }
}

