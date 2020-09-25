//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Sharu on 25/09/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import XCTest

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session:URLSession){
        self.session = session
    }
    
    func get(from url:URL){
        session.dataTask(with: url, completionHandler: (_,_,_ in ))
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_createsDataTaskWithURL() {

        let url = URL(string:"http://any-url.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session:session)
        
        sut.get(from:url)
        
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    // MARK :- Helpers
    
    private class URLSessionSpy: URLSession{
        
        var receivedURLs = [URL]()
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            return fakeURLSessionDataTask()
        }
    }
    
    private class fakeURLSessionDataTask: URLSessionDataTask{
        
    }

}
