//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Sharu on 30/10/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

 func anyURL() -> URL
{
    return URL(string:"https://any-url.com")!
}

 func anyNSError() -> NSError
   {
       return NSError(domain: "any error", code: 0)
   }
