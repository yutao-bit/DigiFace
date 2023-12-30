//
//  UserViewModel.swift
//  TrueDepthStreamer
//
//  Created by iosDeveloper on 2022/7/25.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
class UserViewModel {

    var username = ""
    var password = ""
    var token = ""

    init(){
    }
    init(user: User) {
        self.username = user.username!
        self.password = user.password!
        self.token = user.token!
    }

}



class UserMgr {
    var currentUser:UserViewModel
    static var saveFlag:Bool = false
    init() {
        //fetchAllUsers()
        let users  = CoreDataManager.shared.getAllUsers().map(UserViewModel.init)
        if users.count >= 1 {
            self.currentUser = users[0]
            UserMgr.saveFlag = true
        }
        else{
             self.currentUser = UserViewModel()
            UserMgr.saveFlag = false
        }

    }
    func clear(){
        let users  = CoreDataManager.shared.getAllUsers()
        for item in users {
            CoreDataManager.shared.deleteUser(username: item.username!)
        }
    }
    func login(){
        clear()
        CoreDataManager.shared.saveUser(username: self.currentUser.username,password: self.currentUser.password,token: self.currentUser.token)

        let users  = CoreDataManager.shared.getAllUsers()
        print("\(users)")
    }

    func logout(){
        clear()
        self.currentUser = UserViewModel()
    }
    func deleteUser(_ userVM: UserViewModel) {
        CoreDataManager.shared.deleteUser(username: userVM.username)
       // fetchAllUsers()
    }



}
