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
        //let _ = LocalFeedLoader(store:store,timestamp:Date())
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
    
    private class FeedStoreSpy:FeedStore
    {
        
        enum ReceivedMessage : Equatable{
            case deleteCachedFeed
            case insert([LocalFeedImage],Date)
        }
        
        private(set) var receivedMessages = [ReceivedMessage]()
        
        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()
        
        func deleteCachedFeed(completion:@escaping DeletionCompletion)
        {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedFeed)
        }
        func completeDeletion(with error:Error, at index:Int = 0)
        {
            deletionCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index:Int = 0)
        {
            deletionCompletions[index](nil)
        }
        
        func insert(_ feed: [LocalFeedImage],timestamp:Date, completion:@escaping InsertionCompletion)
        {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(feed,timestamp))
        }
        
        func completeInsertion(with error:Error, at index:Int = 0)
        {
            insertionCompletions[index](error)
        }
        
        func completeInsertionSuccessfully(at index:Int = 0)
        {
            insertionCompletions[index](nil)
        }
    }
       
    
    

}
