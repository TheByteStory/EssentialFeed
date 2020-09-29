//
//  XCTestCase+MemoryLeakTrackingHelper.swift
//  EssentialFeedTests
//
//  Created by Sharu on 29/09/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import XCTest

extension XCTestCase{
func trackForMemoryLeaks(_ instance:AnyObject,file: StaticString = #file, line: UInt = #line){
        addTeardownBlock {[weak instance] in
            XCTAssertNil(instance,"Instance should have been deallocated. Potential memory leak!", file: file, line:line)
        }
    }
}
