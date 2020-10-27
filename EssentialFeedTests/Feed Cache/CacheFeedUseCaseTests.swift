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
    private let currentDate : () -> Date
    
    
    init(store:FeedStore, currentDate:@escaping() -> Date){
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items:[FeedItem], completion:@escaping (Error?) -> Void)
    {
        store.deleteCachedFeed{[unowned self] error in
            completion(error)
            if error == nil
            {
                self.store.insert(items, timestamp:self.currentDate())
            }
            
        }
    
    }
    
}

class FeedStore
{
    typealias DeletionCompletion = (Error?) -> Void
    
    enum ReceivedMessage : Equatable{
        case deleteCachedFeed
        case insert([FeedItem],Date)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    private var deletionCompletions = [DeletionCompletion]()
    
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
    
    func insert(_ items: [FeedItem],timestamp:Date)
    {
        receivedMessages.append(.insert(items,timestamp))
    }
}

class CacheFeedUseCaseTests: XCTestCase {

    //Cache deletion failure
    func test_init_doesNotMessageStoreUponCreation()
    {
        let (_,store) = makeSUT()
        //let _ = LocalFeedLoader(store:store,timestamp:Date())
        XCTAssertEqual(store.receivedMessages, [])

    }
    
    //Cache deletion successful
    func test_save_requestsCacheDeletion()
    {
        let items = [uniqueItem(),uniqueItem()]
        let (sut,store) = makeSUT()
        sut.save(items) {_ in }
        XCTAssertEqual(store.receivedMessages,[.deleteCachedFeed])
    }
    
    //If cache deletion fails, do not insert new cache
    func test_save_doesNotRequestCacheInsertionOnDeletionError()
    {
        let items = [uniqueItem(),uniqueItem()]
        let (sut,store) = makeSUT()
        let deletionError = anyNSError()

        sut.save(items) {_ in }
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages,[.deleteCachedFeed])

    }
    
    
    //New feed items inserted as cache with timestamp
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion()
       {
           let timestamp = Date()
           let items = [uniqueItem(),uniqueItem()]
           let (sut,store) = makeSUT(currentDate: { timestamp })


           sut.save(items) {_ in }
           store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages,[.deleteCachedFeed,.insert(items,timestamp)])
       }
    
    //If cache deletion fails, deletion error
    func test_save_failsOnDeletionError()
    {
        let items = [uniqueItem(),uniqueItem()]
        let (sut,store) = makeSUT()
        let deletionError = anyNSError()
        let exp = expectation(description:"Wait for save completion")

        var receivedError:Error?
        sut.save(items){ error in
          receivedError = error
            exp.fulfill()
        }
        store.completeDeletion(with: deletionError)
        wait(for: [exp],timeout:1.0)

        XCTAssertEqual(receivedError as NSError?,deletionError)


    }
    
    
    //MARK :- Helpers
    
    private func makeSUT(currentDate:@escaping() -> Date = Date.init, file:StaticString = #file,line:UInt = #line) -> (sut:LocalFeedLoader, store:FeedStore)
    {
        let store = FeedStore()
        let sut = LocalFeedLoader(store:store, currentDate:currentDate)
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
