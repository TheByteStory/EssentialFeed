//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Sharu on 03/11/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import XCTest
import EssentialFeed

class CodableFeedStore : FeedStore
{
    //Codable - type alias confirming to both encodable and decodable protocols
    private struct Cache : Codable {
        let feed : [CodableFeedImage]
        let timestamp : Date
        
        var localFeed : [LocalFeedImage]{
            return feed.map { $0.local }
        }
    }
    
    //Framework specific model mirrors the local feed image
    private struct CodableFeedImage : Codable{
        private let id : UUID
        private let description : String?
        private let location : String?
        private let url : URL
        
        init(_ image: LocalFeedImage){
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage{
            return LocalFeedImage(id: id, description: description, location: location, imageURL: url)
        }
    }
    
    private let storeURL:URL
    
    init(storeURL:URL)
    {
        self.storeURL = storeURL
    }
    
    //Decode the cache model
    func retrieve(completion : @escaping RetrievalCompletion)
    {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        
            do{
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
            }catch
            {
                completion(.failure(error))
            }
        
    }
    
    //Encode the cache model
    func insert(_ feed: [LocalFeedImage],timestamp:Date, completion:@escaping InsertionCompletion)
    {
        do {
            let encoder = JSONEncoder()
            let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
            let encoded = try encoder.encode(cache)
            //storeURL is a location in the disk
            try encoded.write(to:storeURL)
            completion(nil)
        }catch{
            completion(error)
        }
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
             return completion(nil)
         }
        do {
             try FileManager.default.removeItem(at: storeURL)
             completion(nil)
         } catch {
             completion(error)
         }
     }
}

class CodableFeedStoreTests: XCTestCase {
    
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
    expect(sut, toRetrieve: .empty)
    }
    
    //retrieving cache twice without side effects
    func test_retrieve_hasNoSideEffectsOnEmptyCache()
    {
        
    let sut = makeSUT()

    expect(sut, toRetrieveTwice: .empty)
    }
    
    //Both cases - insert and retrieve - Empty cache stores data and non-empty cache shows data
    func test_retrieve_deliversFoundValuesOnNonEmptyCache()
    {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timestamp), to: sut)
        expect(sut,toRetrieve: .found(feed:feed,timestamp:timestamp))
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
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache()
    {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timestamp), to: sut)
        expect(sut, toRetrieveTwice: .found(feed:feed,timestamp:timestamp))
    }
    
    //Overrides old cache and inserts new cache
    func test_insert_overridesPreviouslyInsertedCacheValues() {
         let sut = makeSUT()

         let firstInsertionError = insert((uniqueImageFeed().local, Date()), to: sut)
         XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")

         let latestFeed = uniqueImageFeed().local
         let latestTimestamp = Date()
         let latestInsertionError = insert((latestFeed, latestTimestamp), to: sut)

         XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
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
         expect(sut, toRetrieve: .empty)
     }
    
    //Deleting an already empty cache has no problems - sideeffects
    func test_delete_hasNoSideEffectsOnEmptyCache() {
         let sut = makeSUT()
         let deletionError = deleteCache(from: sut)
         XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
         expect(sut, toRetrieve: .empty)
     }
    
    //Deleting a non empty cache empties old cache
    func test_delete_emptiesPreviouslyInsertedCache() {
         let sut = makeSUT()
         insert((uniqueImageFeed().local, Date()), to: sut)
         let deletionError = deleteCache(from: sut)
         XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
         expect(sut, toRetrieve: .empty)
     }
    
    //delete cache Error case - no delete permission
    func test_delete_deliversErrorOnDeletionError() {
         let noDeletePermissionURL = cachesDirectory()
         let sut = makeSUT(storeURL: noDeletePermissionURL)

         let deletionError = deleteCache(from: sut)

         XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
         expect(sut, toRetrieve: .empty)
     }
    
    //MARK :- Helpers
    
    private func makeSUT(storeURL:URL? = nil, file : StaticString = #file, line : UInt = #line) -> CodableFeedStore
    {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file:file, line: line)
        return sut
    }
    
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) -> Error? {
         let exp = expectation(description: "Wait for cache insertion")
        
            var insertionError: Error?
            sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
                insertionError = receivedInsertionError
                
             exp.fulfill()
         }
         wait(for: [exp], timeout: 1.0)
         return insertionError
     }
    
    private func deleteCache(from sut: CodableFeedStore) -> Error? {
         let exp = expectation(description: "Wait for cache deletion")
         var deletionError: Error?
         sut.deleteCachedFeed { receivedDeletionError in
             deletionError = receivedDeletionError
             exp.fulfill()
         }
         wait(for: [exp], timeout: 1.0)
         return deletionError
     }
    
    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrievedCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrievedCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
         let exp = expectation(description: "Wait for cache retrieval")

         sut.retrieve { retrievedResult in
             switch (expectedResult, retrievedResult) {
             case (.empty, .empty),
                  (.failure, .failure):
                 break

             case let (.found(expected), .found(retrieved)):
                 XCTAssertEqual(retrieved.feed, expected.feed, file: file, line: line)
                 XCTAssertEqual(retrieved.timestamp, expected.timestamp, file: file, line: line)

             default:
                 XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
             }

             exp.fulfill()
         }

         wait(for: [exp], timeout: 1.0)
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
