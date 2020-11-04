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
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }

    //Show empty on Empty cache - retrieves once
    func test_retrieve_deliversEmptyOnEmptyCache()
    {
    let sut = makeSUT()
    let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve{ result in
            switch result{
                case .empty:
                    break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for:[exp], timeout: 1.0)
    }
    
    //retrieving cache twice without side effects
    func test_retrieve_hasNoSideEffectsOnEmptyCache()
    {
        
    let sut = makeSUT()
    let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve{ firstResult in
            sut.retrieve{ secondResult in
                    switch (firstResult, secondResult) {
                    case (.empty,.empty):
                        break
                    default:
                        XCTFail("Expected empty result, got \(firstResult) and \(secondResult) instead")
                    }
                    exp.fulfill()
                }
        }
        wait(for:[exp], timeout: 1.0)
    }
    
    //Both cases - insert and retrieve - Empty cache stores data and non-empty cache shows data
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues()
    {
    let sut = makeSUT()
    let feed = uniqueImageFeed().local
    let timestamp = Date()
    let exp = expectation(description: "Wait for cache retrieval")

        sut.insert(feed,timestamp: timestamp){ insertionError in
            XCTAssertNil(insertionError,"Expected feed to be inserted successfully")
            
            sut.retrieve{ retrieveResult in
                    switch (retrieveResult) {
                    case let .found(retrievedFeed,retrivedTimestamp):
                        XCTAssertEqual(retrievedFeed,feed)
                        XCTAssertEqual(retrivedTimestamp,timestamp)
                    default:
                        XCTFail("Expected found result with \(feed) and \(timestamp), got \(retrieveResult) instead")
                    }
                    exp.fulfill()
                }
        }
        wait(for:[exp], timeout: 1.0)
    }
    
    //MARK :- Helpers
    
    private func makeSUT(file : StaticString = #file, line : UInt = #line) -> CodableFeedStore
    {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file:file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL
    {
        //type of self is the class name : CodableFeedStoreTests
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of:self)).store")
    }

}
