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
