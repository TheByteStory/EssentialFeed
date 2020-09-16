//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Sharu on 29/08/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation
import XCTest

@testable import EssentialFeed

class RemoteFeedLoaderTests : XCTestCase
{
    
    func test_init_doesNotRequestDataFromURL()
    {
        let(_,client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL()
    {
        let givenurl = URL(string:"https://a-given-url.com")!
        let (sut,client) = makeSUT(givenurl:givenurl)
        sut.load{_ in }
        XCTAssertEqual(client.requestedURLs,[givenurl])
    }
    
    func test_loadTwice_requestsDataFromURLTwice()
    {
        let givenurl = URL(string:"https://a-given-url.com")!
        let (sut,client) = makeSUT(givenurl:givenurl)
        sut.load{_ in }
        sut.load{_ in }
        XCTAssertEqual(client.requestedURLs,[givenurl,givenurl])
    }
    
    
    func test_load_deliversErrorOnClientError(){
        let(sut,client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.connectivity), when: {let clientError = NSError(domain: "Test", code: 0)
            client.complete(with:clientError)})
        
        
    }
    
    func test_load_deliversErrorOnNon200HttpResponse(){
        let(sut,client) = makeSUT()
        
        let samples = [199, 201,300,400,500]
        
        samples.enumerated().forEach{index, code in
            
            expect(sut, toCompleteWith: .failure(.invalidData),when: { client.complete(withStatusCode:code,at: index)})
        }
    }
    
    func test_load_deliversErrorOn200ResponseWithInvalidJSON(){
        let(sut,client) = makeSUT()
        
        expect(sut, toCompleteWith:.failure(.invalidData), when: {
            let invalidJSON = Data(bytes:"invalid JSON".utf8)
            client.complete(withStatusCode:200,
            data:invalidJSON)
            
        })
        
          
    }
    
   func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList()
    {
        let(sut,client) = makeSUT()
        
       var capturedResults = [RemoteFeedLoader.Result]()
                  sut.load{capturedResults.append($0)}
        expect(sut,toCompleteWith:.success([]),when:{
            let emptyListJSON = Data(bytes:"{\"items\":[]}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
        
        
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems()
    {
        let(sut,client) = makeSUT()
        
        let item1 = FeedItem(
            id: UUID(),
            description: nil,
            location: nil,
            imageURL: URL(string: "http://a-url.com")!)
            
        
        let item1JSON = [
            "id":item1.id.uuidString,
            "image":item1.imageURL.absoluteString
        ]
        
        
        let item2 = FeedItem(
            id: UUID(),
            description: "a description ",
            location: "a location   ",
            imageURL: URL(string: "http://another-url.com")!)
        
        let item2JSON = [
            "id":item2.id.uuidString,
            "description":item2.desctiption,
            "location":item2.location,
            "image":item2.imageURL.absoluteString
        ]
        
        let itemsJSON = [
            "items":[item1JSON,item2JSON]
        ]
        
        expect(sut,toCompleteWith: .success([item1,item2]),when:{
            let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
            client.complete(withStatusCode: 200, data: json)
        } )
    }
    
    
    // Mark:- Helpers
    
    private func makeSUT(givenurl:URL = URL(string: "https://a-url.com")!) ->
        (sut:RemoteFeedLoader,client:HttpClientSpy){
            
        let client = HttpClientSpy()
            let sut = RemoteFeedLoader(url: givenurl, client: client)
        return(sut,client)
    }
    
    private func expect(_ sut:RemoteFeedLoader,toCompleteWith result:RemoteFeedLoader.Result,when action:() ->Void, file: StaticString = #file, line: UInt = #line)
    
    {
        var capturedResults = [RemoteFeedLoader.Result]()
                   sut.load{capturedResults.append($0)}
                   
        action()
               
        XCTAssertEqual(capturedResults, [result], file:file, line:line)
        
    }
    
    
    private class HttpClientSpy : HTTPClient{
         
        var requestedURLs : [URL]{
            return messages.map {$0.url}
            
        }
        
        
        private var messages = [(url:URL, completion:(HTTPClientResult) -> Void)]()
        
        func get(from url:URL, completion:@escaping(HTTPClientResult) -> Void){
            
            messages.append((url, completion))
        }
        
        func complete(with error:Error, at index:Int = 0)
        {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code:Int, data:Data = Data(),at index: Int = 0)
        {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
            
            messages[index].completion(.success(data,response))
        }
        
    }
}
  
