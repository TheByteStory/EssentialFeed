//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Sharu on 02/12/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import XCTest
import EssentialFeed

class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {

    func test_retrieve_deliversEmptyOnEmptyCache() {

           let sut = makeSUT()

           assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
       }

       func test_retrieve_hasNoSideEffectsOnEmptyCache() {
       }
       
       func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
       }
       
       func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
       }
       
       func test_insert_deliversNoErrorOnEmptyCache() {
       }
       
       func test_insert_deliversNoErrorOnNonEmptyCache() {
       }
       
       func test_insert_overridesPreviouslyInsertedCacheValues() {
    

       }
    
    
    // - MARK: Helpers
     
     private func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedStore {
         let sut = CoreDataFeedStore()
         trackForMemoryLeaks(sut, file: file, line: line)
         return sut
     }

}
