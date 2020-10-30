//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Sharu on 26/10/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import XCTest
import EssentialFeed






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
        let (sut,store) = makeSUT()
        sut.save(uniqueImageFeed().models) {_ in }
        XCTAssertEqual(store.receivedMessages,[.deleteCachedFeed])
    }
    
    //If cache deletion fails, do not insert new cache
    func test_save_doesNotRequestCacheInsertionOnDeletionError()
    {
        let (sut,store) = makeSUT()
        let deletionError = anyNSError()

        sut.save(uniqueImageFeed().models) {_ in }
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages,[.deleteCachedFeed])

    }
    
    
    //New feed items inserted as cache with timestamp
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion()
       {
           let timestamp = Date()
           let feed = uniqueImageFeed()
           let (sut,store) = makeSUT(currentDate: { timestamp })


        sut.save(feed.models) {_ in }
           store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages,[.deleteCachedFeed,.insert(feed.local,timestamp)])
        
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
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models) { receivedResults.append($0)}
        
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
        sut?.save(uniqueImageFeed().models) { receivedResults.append($0)}
        
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
        sut.save(uniqueImageFeed().models){ error in
          receivedError = error
            exp.fulfill()
        }
        action()
        wait(for: [exp],timeout:1.0)

    XCTAssertEqual(receivedError as NSError?,expectedError, file:file, line:line)
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

    
    

}
