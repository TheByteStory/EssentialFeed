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
    func test_validateCache_doesNotDeleteOnLessThanSevenDaysOldCache()
    {
        let feed = uniqueImageFeed()
        
        let fixedCurrentDate = Date()
        
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds:1)
        
        let (sut,store) = makeSUT(currentDate: { fixedCurrentDate })
                
        sut.validateCache()
        
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages,[.retrieve])
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
    
    private func uniqueImage() -> FeedImage
    {
        return FeedImage(id:UUID(),description:"any",location:"any",url:anyURL())
    }
    
    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage])
    {
        let models = [uniqueImage(), uniqueImage()]
        let local = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.url) }
        return(models,local)
    }


    private func anyNSError() -> NSError
    {
        return NSError(domain: "any error", code: 0)
    }
    
    private func anyURL() -> URL
    {
        return URL(string:"https://any-url.com")!
    }
    

}

private extension Date {
    func adding(days:Int) -> Date{
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date{
        return self + seconds
    }
}
