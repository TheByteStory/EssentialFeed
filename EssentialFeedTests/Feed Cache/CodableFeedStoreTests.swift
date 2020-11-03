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
    func retrieve(completion : @escaping FeedStore.RetrievalCompletion)
    {
        completion(.empty)
    }
}

class CodableFeedStoreTests: XCTestCase {

    //Show empty on Empty cache - retrieves once
    func test_retrieve_deliversEmptyOnEmptyCache()
    {
    let sut = CodableFeedStore()
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
    let sut = CodableFeedStore()
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
    

    
//    //With Non Empty cache,override the old value
//    func test_retrieve_nonEmptyCacheOverridesPreviousValue()
//    {
//        let sut = CodableFeedStore()
//        let exp = expectation(description: "Wait for cahe retrieval")
//
//        sut.retrieve{ result in
//
//            switch result{
//            case (notempty):
//                delete old cache
//                replace with new cache
//            }
//        }
//    }
}
