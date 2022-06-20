//
//  CKPublicDataManager.swift
//  NFTY
//
//  Created by Varun Kohli on 6/19/22.
//

import Foundation
import CoreData
import CloudKit

// https://github.com/imtherb91/CoreDataCloudKit/blob/master/CoreDataCloudKit/CoreDataManager.swift
class CKPublicDataManager {
  
  static let shared = CKPublicDataManager()
  
  // MARK: - Core Data stack
  
  lazy var persistentContainer: NSPersistentCloudKitContainer = {
    let container = NSPersistentCloudKitContainer(name: "CKPublicObjects")
    guard let description = container.persistentStoreDescriptions.first else {
      fatalError("###\(#function): Failed to retrieve persistent store description.")
    }
    
#if DEBUG
    do {
      // Use the container to initialize the development schema.
      try container.initializeCloudKitSchema(options: [])
    } catch {
      // Handle any errors.
    }
#endif
    
    description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.nftygo.NFTY")
    description.cloudKitContainerOptions!.databaseScope = .public
    
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()
  
  var managedContext: NSManagedObjectContext {
    let context = persistentContainer.viewContext
    context.automaticallyMergesChangesFromParent = true
    return context
  }
  
  // MARK: - Core Data Saving support
  
  /* func saveContext () {
    let context = persistentContainer.viewContext
    context.mergePolicy =  NSMergeByPropertyObjectTrumpMergePolicy
    if context.hasChanges {
      do {
        print("Trying to save")
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
   */
  
}
