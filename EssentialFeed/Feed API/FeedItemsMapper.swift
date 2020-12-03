//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Sharu on 21/09/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation



internal final class FeedItemsMapper {
    
    internal struct RemoteFeedItem : Decodable{
     internal let id : UUID
     internal let description : String?
     internal let location : String?
     internal let image : URL
    }
    
    private struct Root:Decodable
    {
        let items:[RemoteFeedItem]
    }
<<<<<<< HEAD
    
    
    
    private static var OK_200 : Int{return 200}
    
    internal static func map(_ data:Data,from response:HTTPURLResponse) throws -> [RemoteFeedItem]
=======
    
    private static var OK_200 : Int{return 200}
    
    internal static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem]
>>>>>>> temp-branch
    {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self,from:data) else
        {
            throw RemoteFeedLoader.Error.invalidData
        }
        return root.items
           
    }
    
}
