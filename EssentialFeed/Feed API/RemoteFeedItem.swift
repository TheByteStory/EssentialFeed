//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Sharu on 28/10/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import Foundation

internal struct RemoteFeedItem : Decodable{
 internal let id : UUID
 internal let description : String?
 internal let location : String?
 internal let image : URL
}
