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
        let retrievalError = anyNSError()
        
        expect(sut,toCompleteWith: .failure(retrievalError),when: {
            store.completeRetrieval(with: retrievalError)

        })
    }
    
    //No images on empty cache
    func test_load_deliversNoImagesOnEmptyCache()
    {
        let (sut,store) = makeSUT()
        expect(sut, toCompleteWith: .success([]), when:
            {
                store.completeRetrievalWithEmptyCache()
            })
        
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
    
    private func expect(_ sut:LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action:() -> Void, file:StaticString = #file,line:UInt = #line)
    {
        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult,expectedResult) {
            case let (.success(receivedImages),.success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages,file:file, line:line)
            case let(.failure(receivedError as NSError),.failure(expectedError as NSError)):
                XCTAssertEqual(receivedError,expectedError, file:file, line:line)
            default:
                XCTFail("Expected Result \(expectedResult) got \(receivedResult) instead", file:file, line:line)
            }
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }


    private func anyNSError() -> NSError
    {
        return NSError(domain: "any error", code: 0)
    }
    
}
