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
    let container = NSPersistentContainer(name: "ImmutableObjects")
    // let description = container.persistentStoreDescriptions.first
    // description?.setOption(true as NSNumber,forKey: NSPersistentHistoryTrackingKey)
    
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()
  
}
