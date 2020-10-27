//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Sharu on 26/10/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import XCTest
import EssentialFeed

class LocalFeedLoader
{
    private let store:FeedStore
    
    
    
    init(store:FeedStore){
        self.store = store
    }
    
    func save(_ items:[FeedItem])
    {
        store.deleteCachedFeed()
    }
    
    
}

class FeedStore
{
    var insertCallCount = 0
    var deleteCachedFeedCallCount = 0
    
    func deleteCachedFeed()
    {
        deleteCachedFeedCallCount += 1
    }
    func completeDeletion(with error:Error, at index:Int = 0)
    {

    }
}

class CacheFeedUseCaseTests: XCTestCase {

    //Cache deletion failure
    func test_init_doesNotDeleteCacheUponCreation()
    {
        let (_,store) = makeSUT()
        let _ = LocalFeedLoader(store:store)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    //Cache deletion successful
    func test_save_requestsCacheDeletion()
    {
        let items = [uniqueItem(),uniqueItem()]
        let (sut,store) = makeSUT()
        sut.save(items)
        XCTAssertEqual(store.deleteCachedFeedCallCount,1)
    }
    
    //If cache deletion fails, do not insert new cache
    func test_save_doesNotRequestCacheInsertionOnDeletionError()
    {
        let items = [uniqueItem(),uniqueItem()]
        let (sut,store) = makeSUT()
        var deletionError = anyNSError()
        
        
        sut.save(items)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCount,0)
        
    }
    
    
    
    //MARK :- Helpers
    
    private func makeSUT(file:StaticString = #file,line:UInt = #line) -> (sut:LocalFeedLoader, store:FeedStore)
    {
        let store = FeedStore()
        let sut = LocalFeedLoader(store:store)
        trackForMemoryLeaks(store,file:file,line:line)
        trackForMemoryLeaks(sut,file:file,line:line)
        return(sut,store)
    }
    
    private func uniqueItem() -> FeedItem
    {
        return FeedItem(id:UUID(),description:"any",location:"any",imageURL:anyURL())
    }
    
    private func anyURL() -> URL
    {
        return URL(string:"https://any-url.com")!
    }
    
    private func anyNSError() -> NSError
       {
           return NSError(domain: "any error", code: 0)
       }

}
