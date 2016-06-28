//
//  CoreDataStack.swift
//  tstIngrm
//
//  Created by Круцких Олег on 28.06.16.
//  Copyright © 2016 Круцких Олег. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    var context: NSManagedObjectContext
    var psc: NSPersistentStoreCoordinator
    var model: NSManagedObjectModel
    var store: NSPersistentStore?
    
    init() {
        
        let bundle = NSBundle.mainBundle()
        let modelURL = bundle.URLForResource("tstIngrm", withExtension:"momd")
        model = NSManagedObjectModel(contentsOfURL: modelURL!)!
        
        psc = NSPersistentStoreCoordinator(managedObjectModel:model)
        
        context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = psc
        
        let documentsURL = applicationDocumentsDirectory()
        let storeURL =
            documentsURL.URLByAppendingPathComponent("tstIngrm.sqlite")
        
        let options =
            [NSMigratePersistentStoresAutomaticallyOption: true]
        
        do {
            try store = psc.addPersistentStoreWithType(NSSQLiteStoreType,
                                                       configuration: nil,
                                                       URL: storeURL,
                                                       options: options)
        } catch {
            debugPrint("Error adding persistent store: \(error)")
            abort()
        }
        
    }
    
    func saveContext() {
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                debugPrint("Could not save: \(error)")
            }
        }
    }
    
    func applicationDocumentsDirectory() -> NSURL {
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }
    
}