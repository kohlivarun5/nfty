//
//  CoreDataManager.swift
//  NFTY
//
//  Created by Varun Kohli on 6/19/22.
//

import Foundation
import CoreData

class CoreDataManager {
  
  static let shared = CoreDataManager()
  
  // MARK: - Core Data stack
  
  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "CKPublicObjects")
    // let description = container.persistentStoreDescriptions.first
    // description?.setOption(false as NSNumber,forKey: NSPersistentHistoryTrackingKey)
    
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
  
  func saveContext () {
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
  
  
}
