//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Sharu on 30/10/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import XCTest
import EssentialFeed

class ValidateFeedCacheUseCaseTests: XCTestCase {

    //Local Feed Loader does not message store upon creation - not duplicating code. we are testing the same thing but with a different context.
    func test_init_doesNotMessageStoreUponCreation()
    {
        let (_,store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])

    }
    
    //Deletes cache on retrieval error
    func test_validatesCache_deletesCacheOnRetrievalError()
    {
        let(sut,store) = makeSUT()
        
        sut.validateCache()
        
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages,[.retrieve,.deleteCachedFeed])
    }
    
    //Does not delete cache on empty cache
    func test_validateCache_hasNoSideEffectsOnEmptyCache()
       {
           let(sut,store) = makeSUT()
           
           sut.validateCache()
           
           store.completeRetrievalWithEmptyCache()
           
           XCTAssertEqual(store.receivedMessages,[.retrieve])
       }
    
    //Does not delete cache on less than seven days old cache
    func test_validateCache_doesNotDeleteNonExpiredCache()
    {
        let feed = uniqueImageFeed()
        
        let fixedCurrentDate = Date()
        
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds:1)
        
        let (sut,store) = makeSUT(currentDate: { fixedCurrentDate })
                
        sut.validateCache()
        
        store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages,[.retrieve])
    }
    
    //Should delete 7 days old cache
    func test_validateCache_deletesCacheOnExpiration()
    {
        let feed = uniqueImageFeed()
        
        let fixedCurrentDate = Date()
        
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        
        let (sut,store) = makeSUT(currentDate: { fixedCurrentDate })
                
        sut.validateCache()
        
        store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
        
        XCTAssertEqual(store.receivedMessages,[.retrieve,.deleteCachedFeed])
    }
    
    //Should delete more than 7 days old cache
    func test_validateCache_deletesExpiredCache()
    {
        let feed = uniqueImageFeed()
        
        let fixedCurrentDate = Date()
        
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        
        let (sut,store) = makeSUT(currentDate: { fixedCurrentDate })
                
        sut.validateCache()
        
        store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages,[.retrieve,.deleteCachedFeed])
    }
    
    //does not delete invalid cache after SUT deallocation
    func test_load_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut:LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        sut?.validateCache()
        
        sut = nil
        
        store.completeRetrieval(with: anyNSError())
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    //MARK :- Helpers
          
          private func makeSUT(currentDate:@escaping() -> Date = Date.init, file:StaticString = #file,line:UInt = #line) -> (sut:LocalFeedLoader, store:FeedStoreSpy)
          {
              let store = FeedStoreSpy()
              let sut = LocalFeedLoader(store:store, currentDate:currentDate)
              trackForMemoryLeaks(store,file:file,line:line)
              trackForMemoryLeaks(sut,file:file,line:line)
              return(sut,store)
          }
    
    
    

}

