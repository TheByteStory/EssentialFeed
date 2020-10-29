//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Sharu on 29/10/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import XCTest
import EssentialFeed

//Cache is ready now. Load image feed from the cache.

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    //Local Feed Loader does not message store upon creation
    func test_init_doesNotMessageStoreUponCreation()
    {
        let (_,store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])

    }
    
    //Cache retrieval from feedstore
    func test_load_requestsCacheRetrieval()
    {
        let (sut,store) = makeSUT()
        
        sut.load{_ in }
               
        XCTAssertEqual(store.receivedMessages, [.retrieve])

    }
    
    //Cache retrieval fails
    func test_load_failsOnRetrievalError()
    {
        let (sut,store) = makeSUT()
        var retrievalError = anyNSError()
        let exp = expectation(description: "Wait for load completion")
        var receivedError : Error?
        sut.load{ result in
            switch result{
            case let .failure(error):
                receivedError = error
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        store.completeRetrieval(with: retrievalError)
        wait(for: [exp], timeout: 1.0)
               
        XCTAssertEqual(receivedError as NSError?, retrievalError)

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
    
    private func anyNSError() -> NSError
    {
        return NSError(domain: "any error", code: 0)
    }
    
}
