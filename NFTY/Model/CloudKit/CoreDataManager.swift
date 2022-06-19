//
//  CoreDataManager.swift
//  NFTY
//
//  Created by Varun Kohli on 6/18/22.
//

import Foundation
import CoreData
import CloudKit

// https://iosapptemplates.com/blog/ios-development/data-persistence-ios-swift

class CoreDataManager {
  
  init() {}
  
  private lazy var persistentContainer: NSPersistentContainer = {
    
    //let container = NSPersistentContainer(name: persistentStoreName)
    // OR - Include the following line for use with CloudKit - NSPersistentCloudKitContainer
    let container = NSPersistentCloudKitContainer(name: "CoreDataModel")
    // following block added 12-11-21 following apple video tutorial
    guard let description = container.persistentStoreDescriptions.first else {
      fatalError("###\(#function): Failed to retrieve persistent store description.")
    }
    description.cloudKitContainerOptions?.databaseScope = .public
    
    container.loadPersistentStores(completionHandler: { _, error in
      _ = error.map { fatalError("Unresolved error \($0)") }
    })
    return container
  }()
  
  var mainContext: NSManagedObjectContext {
    return persistentContainer.viewContext
  }
  
  func backgroundContext() -> NSManagedObjectContext {
    return persistentContainer.newBackgroundContext()
  }
}
