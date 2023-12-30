//
//  CoreDataManager.swift
//  TrueDepthStreamer
//
//  Created by iosDeveloper on 2022/7/25.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {

    static let shared = CoreDataManager(moc: NSManagedObjectContext.current)

    var moc: NSManagedObjectContext

    private init(moc: NSManagedObjectContext) {
        self.moc = moc
    }

    private func fetchUser(username: String) -> User? {

        var orders = [User]()

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", username)

        do {
            orders = try self.moc.fetch(request)
        } catch let error as NSError {
            print(error)
        }

        return orders.first

    }

    func deleteUser(username: String) {

        do {
            if let order = fetchUser(username: username) {
                self.moc.delete(order)
                try self.moc.save()
            }
        } catch let error as NSError {
            print(error)
        }

    }


    func getAllUsers() -> [User] {

        var users = [User]()

        let orderRequest: NSFetchRequest<User> = User.fetchRequest()

        do {
            users = try self.moc.fetch(orderRequest)
        } catch let error as NSError {
            print(error)
        }

        return users

    }

    func saveUser(username: String,password: String,token: String) {

        let user = User(context: self.moc)
        user.username = username
        user.password = password
        user.token = token
        do {
            try self.moc.save()
        } catch let error as NSError {
            print(error)
        }

    }

}
