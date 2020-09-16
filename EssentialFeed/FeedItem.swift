//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Sharu on 28/08/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

public struct FeedItem : Equatable{
    public let id : UUID
    public let desctiption : String?
    public let location : String?
    public let imageURL : URL
    
    public init(id:UUID,description:String?,location:String?,imageURL:URL)
    {
        self.id = id
        self.desctiption = description
        self.location = location
        self.imageURL = imageURL
    }
}

extension FeedItem : Decodable{
    private enum CodingKeys : String,CodingKey{
        case id
        case description
        case location
        case imageURL = "image"
    }
}
