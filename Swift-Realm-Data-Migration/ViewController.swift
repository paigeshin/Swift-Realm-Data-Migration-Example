//
//  ViewController.swift
//  Swift-Realm-Data-Migration
//
//  Created by shin seunghyun on 2020/08/18.
//  Copyright © 2020 paige sofrtware. All rights reserved.
//


//MARK:- Basically, when you change intial schema of RealmSwift, error occurs, crashing the application.

import UIKit
import RealmSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
 
            let configuration = Realm.Configuration(
                schemaVersion: 7,
                migrationBlock: { miggration, oldVersion in
                    
                    //set default value
                    miggration.enumerateObjects(ofType: "User") { (old, new) in
                        new?["title"] = "migrated value"
                    }
                    
                    //handle old, new values with version numbers
                    miggration.enumerateObjects(ofType: "User") { (old, new) in
                        if oldVersion == 5 {
                            if old?["title"] == nil {
                                new?["title"] = "new migrated value"
                            }
                        }
                    }
                    
                    //if you wanted to create object
                    if oldVersion == 6 {
                        miggration.enumerateObjects(ofType: "User") { (old, new) in
                            let passport: MigrationObject = miggration.create("Passport", value: [
                                "passportNumber": "migration passport Number"
                            ])
                            new?["passport"] = passport
                        }
                    }
                    
                    //if you renamed property
                    if oldVersion == 4 {
                        //if you changed `property` name, you must call `reanme Property`
                        miggration.renameProperty(onType: "User", from: "currentUser", to: "isCurrentUser")
                    }

                }
            )
            
            let realm = try Realm(configuration: configuration)
            
            
            let users = realm.objects(User.self)
            for user in users {
                print(user)
            }
            
            
        } catch {
            print(error.localizedDescription)
        }


        
    }


}

class User: Object {
    
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""
    @objc dynamic var userId = 0
    
    @objc dynamic var title: String? = nil //this is 'added field' so it will crash the application
    @objc dynamic var isCurrentUser = false
    @objc dynamic var passport: Passport?
    
    override static func primaryKey() -> String? {
        return "userId"
    }
    
    convenience init(_ firstName: String, _ userId: Int) {
        self.init()
        self.firstName = firstName
        self.userId = userId
    }
    
}

class Passport: Object {
    @objc dynamic var passportNumber = ""
}
