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
        store.deleteCachedFeed{[weak self] error in
            guard let self = self else { return }
            if error == nil
            {
                self.store.insert(items, timestamp:self.currentDate()){[weak self] error in
                    guard self != nil else { return }
                    completion(error)
                }
            }
            else
            {
                completion(error)
            }
            
        }
    
    }
    
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion:@escaping DeletionCompletion)

    func insert(_ items: [FeedItem],timestamp:Date, completion:@escaping InsertionCompletion)

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
        let (sut,store) = makeSUT()
        let deletionError = anyNSError()
        
        expect(sut,toCompleteWithError:deletionError, when:
            {
              store.completeDeletion(with: deletionError)
        })

    }
    
    //Cache deleted successfully but Fails to insert feed items into cache
    func test_save_failsOnInsertionError()
    {
        let (sut,store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWithError:insertionError, when:{
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })

    }
    
    //Happy path - Deletion successful and cache insertion successful
    func test_save_succeedsOnSuccessfulCacheInsertion()
    {
        let (sut,store) = makeSUT()
        
        expect(sut,toCompleteWithError:nil, when:{
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
        

    }
    
    //After sut has been deallocated, no deletion error
    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated()
    {
        let store = FeedStoreSpy()
        var sut:LocalFeedLoader? = LocalFeedLoader(store:store, currentDate:Date.init)
        
        var receivedResults = [Error?]()
        sut?.save([uniqueItem()]) { receivedResults.append($0)}
        
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    //After sut has been deallocated, no insertion error
    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated()
    {
        let store = FeedStoreSpy()
        var sut:LocalFeedLoader? = LocalFeedLoader(store:store, currentDate:Date.init)
        
        var receivedResults = [Error?]()
        sut?.save([uniqueItem()]) { receivedResults.append($0)}
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
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
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action:() -> Void,file:StaticString = #file,line:UInt = #line)
    {
        let exp = expectation(description:"Wait for save completion")

        var receivedError:Error?
        sut.save([uniqueItem()]){ error in
          receivedError = error
            exp.fulfill()
        }
        action()
        wait(for: [exp],timeout:1.0)

    XCTAssertEqual(receivedError as NSError?,expectedError, file:file, line:line)
    }
    
    private class FeedStoreSpy:FeedStore
    {
        
        enum ReceivedMessage : Equatable{
            case deleteCachedFeed
            case insert([FeedItem],Date)
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
        
        func insert(_ items: [FeedItem],timestamp:Date, completion:@escaping InsertionCompletion)
        {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(items,timestamp))
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
