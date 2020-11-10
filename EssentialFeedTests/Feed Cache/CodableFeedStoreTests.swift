//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Sharu on 03/11/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import XCTest
import EssentialFeed


class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs  {
   
    
    //Remove artifacts every time - use setup instead of teardown
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        UndoStoreSideEffects()
    }

    //Show empty on Empty cache - retrieves once
    func test_retrieve_deliversEmptyOnEmptyCache()
    {
        let sut = makeSUT()
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    //retrieving cache twice without side effects
    func test_retrieve_hasNoSideEffectsOnEmptyCache()
    {
        
        let sut = makeSUT()
        expect(sut,toRetrieveTwice: .empty)
    }
    
    //Both cases - insert and retrieve - Empty cache stores data and non-empty cache shows data
    func test_retrieve_deliversFoundValuesOnNonEmptyCache()
    {
        let sut = makeSUT()
        //assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    //Error case - retrieve once
    func test_retrieve_deliversFailureOnRetrievalError()
    {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL:storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    //Error case - retrieve twice
    func test_retrieve_hasNoSideEffectsOnFailure()
    {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL:storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
    
    //Retrieve non-empty cache twice
    func test_insert_deliversNoErrorOnEmptyCache()
    {
        let sut = makeSUT()

        let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully")
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
         let sut = makeSUT()
         insert((uniqueImageFeed().local, Date()), to: sut)

         let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)

         XCTAssertNil(insertionError, "Expected to override cache successfully")
     }
    
    //Overrides old cache and inserts new cache
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        insert((uniqueImageFeed().local, Date()), to: sut)
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert((latestFeed, latestTimestamp), to: sut)

        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
     }
    
    //Cache insertion error
    func test_insert_deliversErrorOnInsertionError() {
         let invalidStoreURL = URL(string: "invalid://store-url")!
         let sut = makeSUT(storeURL: invalidStoreURL)
         let feed = uniqueImageFeed().local
         let timestamp = Date()

         let insertionError = insert((feed, timestamp), to: sut)

         XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
     }
    
    //Cache insertion error - no side effects - just an empty retrieval
    func test_insert_hasNoSideEffectsOnInsertionError() {
         let invalidStoreURL = URL(string: "invalid://store-url")!
         let sut = makeSUT(storeURL: invalidStoreURL)
         let feed = uniqueImageFeed().local
         let timestamp = Date()

         insert((feed, timestamp), to: sut)

         expect(sut, toRetrieve: .empty)
     }

    
    //Deleting an already empty cache
    func test_delete_deliversNoErrorOnEmptyCache() {
         let sut = makeSUT()
         let deletionError = deleteCache(from: sut)
         XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
     }
    
    //No side effects on delete
    func test_delete_hasNoSideEffectsOnEmptyCache() {
         let sut = makeSUT()

         deleteCache(from: sut)

         expect(sut, toRetrieve: .empty)
     }

    
    //Deleting a non empty cache empties old cache
    func test_delete_deliversNoErrorOnNonEmptyCache() {
         let sut = makeSUT()
         insert((uniqueImageFeed().local, Date()), to: sut)
         let deletionError = deleteCache(from: sut)
         XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
     }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
         let sut = makeSUT()
         insert((uniqueImageFeed().local, Date()), to: sut)

         deleteCache(from: sut)

         expect(sut, toRetrieve: .empty)
     }
    
    //delete cache Error case - no delete permission
    func test_delete_deliversErrorOnDeletionError() {
         let noDeletePermissionURL = cachesDirectory()
         let sut = makeSUT(storeURL: noDeletePermissionURL)

         let deletionError = deleteCache(from: sut)

         XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
     }
    
    //delete cache Error case - has no side effects
    func test_delete_hasNoSideEffectsOnDeletionError() {
         let noDeletePermissionURL = cachesDirectory()
         let sut = makeSUT(storeURL: noDeletePermissionURL)

         deleteCache(from: sut)

         expect(sut, toRetrieve: .empty)
     }
    
    //Store side-effects run serially - Insert should finish before delete every single time
    func test_storeSideEffects_runSerially()
    {
        let sut = makeSUT()
        var completedOperationsInOrder = [XCTestExpectation]()
        
        let op1 = expectation(description: "Operation 1 - Insertion")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2 - Deletion")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3 - Another Insertion")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(completedOperationsInOrder, [op1,op2,op3], "Expected side-effects to run serially but operations finished in the wrong order")
        
    }
    
    //MARK :- Helpers
    
    private func makeSUT(storeURL:URL? = nil, file : StaticString = #file, line : UInt = #line) -> FeedStore
    {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file:file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL
    {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")

    }
    
    private func cachesDirectory() -> URL {
         return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
     }
    
    private func setupEmptyStoreState()
    {
        deleteStoreArtifacts()
    }
    
    private func UndoStoreSideEffects()
    {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts()
    {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())

    }

}
