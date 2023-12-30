/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements the app delegate for TrueDepth Streamer
*/

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    lazy var persistentContainer: NSPersistentContainer = {

        let container = NSPersistentContainer(name: "userprofile")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
         if let error = error {

          fatalError("Unresolved error, \((error as NSError).userInfo)")
         }
        })
        return container
    }()
}

extension NSManagedObjectContext {
    
    static var current: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
}

