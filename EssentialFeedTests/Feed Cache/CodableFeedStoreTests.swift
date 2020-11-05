//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Sharu on 03/11/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import XCTest
import EssentialFeed

class CodableFeedStore
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
    func retrieve(completion : @escaping FeedStore.RetrievalCompletion)
    {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        
    }
    
    //Encode the cache model
    func insert(_ feed: [LocalFeedImage],timestamp:Date, completion:@escaping FeedStore.InsertionCompletion)
    {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        //storeURL is a location in the disk
        try! encoded.write(to:storeURL)
        completion(nil)
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
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues()
    {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timestamp), to: sut)
        expect(sut,toRetrieve: .found(feed:feed,timestamp:timestamp))
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
    
    //MARK :- Helpers
    
    private func makeSUT(file : StaticString = #file, line : UInt = #line) -> CodableFeedStore
    {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file:file, line: line)
        return sut
    }
    
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) {
         let exp = expectation(description: "Wait for cache insertion")
         sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
             XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
             exp.fulfill()
         }
         wait(for: [exp], timeout: 1.0)
     }
    
    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrievedCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrievedCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
         let exp = expectation(description: "Wait for cache retrieval")

         sut.retrieve { retrievedResult in
             switch (expectedResult, retrievedResult) {
             case (.empty, .empty):
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
        //type of self is the class name : CodableFeedStoreTests
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of:self)).store")
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
