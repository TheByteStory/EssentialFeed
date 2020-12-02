//
//  CoreDataHelpers.swift
//  EssentialFeed
//
//  Created by Sharu on 02/12/20.
//  Copyright © 2020 Sharu. All rights reserved.
//

import CoreData

internal extension NSPersistentContainer {
   enum LoadingError: Swift.Error {
       case modelNotFound
       case failedToLoadPersistentStores(Swift.Error)
   }

    static func load(modelName name: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer{
       guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
           throw LoadingError.modelNotFound
       }

       let container = NSPersistentContainer(name: name, managedObjectModel: model)
       var loadError: Swift.Error?
       container.loadPersistentStores { loadError = $1 }
       try loadError.map { throw LoadingError.failedToLoadPersistentStores($0) }

       return container
   }
}

private extension NSManagedObjectModel {
   static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
       return bundle
           .url(forResource: name, withExtension: "momd")
           .flatMap { NSManagedObjectModel(contentsOf: $0) }
   }
}
