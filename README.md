# Swift-Realm-Data-Migration-Example

[https://medium.com/@aliakhtar_16369/migration-with-realm-realmswift-part-6-11c3a7b24955](https://medium.com/@aliakhtar_16369/migration-with-realm-realmswift-part-6-11c3a7b24955)

# **Rule of Thumb :**

Avoid Custom migration as much as possible because when you do you need to think many flows

# Solution - 1 (Delete old file)

- Delete the application and run again with the code shown in Figure 3 and you will see we configured realm with deleteRealmIfMigrationNeeded = true which means when there is a mismatch delete the Realm file and create again. In this case you will delete the user’s data every time there is a migration required which is not a good solution

```swift
let configuration = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
let realm = try! Realm(configuration: configuration)
```

# Solution - 2 (Schema Versioning)

- Delete the application and run again with the code shown in Figure 5 and you will see we configured realm with schemaVersion = 1 which means we are telling realm it’s our first version of the schama and if we increment this value do automatic migration.

```swift
let configuration = Realm.Configuration(schemaVersion: 2)
let realm = try! Realm(configuration: configuration)
```

### Advanced Schema Versioning

- give default value
    - `migration`: this is an intance of the Migration helper class, which gives you access to the old and new object schemas. It provides you with methods to access to the old and new object schemas and provides you with methods to access the data in the old and new Realm files

        => access the data in the old and new Realm files.

    - `oldVersion`: this is the schema version of the existing file. The one you're migrating from and in our case it's value is 1 since we are migrating from 1 to 2.

```swift
let configuration = Realm.Configuration(
                schemaVersion: 3,
                migrationBlock: { miggration, oldVersion in
                    miggration.enumerateObjects(ofType: "User") { (old, new) in
                        new?["title"] = "migrated value"
                    }
                }
            )
            
            let realm = try Realm(configuration: configuration)
```

- if you changed property name
    1. In previous stored data we saved User `title` with `nil`, now in our next release if we want to give some value to it we can do it , Note both new and old have title field since both version of the schema has title property
    2. Secondly `Migration.renameProperty(onType:from:to:)`. When you rename a property in your code, Realm has no way to know that a property represents the same thing, given the fact it has a different name. For example, when you rename `currentUser` to `isCurrentUser`, the only information Realm has is that `currentUser` was deleted and `isCurrentUser` was added. Therefore, it deletes all data stored in `currentUser` and adds a new empty property named `isCurrentUser` to the class. To preserve the existing data stored on disk, you need to help Realm by adding the following to your migration block:

```swift
let configuration = Realm.Configuration(
    schemaVersion: 5,
    migrationBlock: { miggration, oldVersion in
        miggration.enumerateObjects(ofType: "User") { (old, new) in
            if oldVersion == 2 {
                if old?["title"] == nil {
                    new?["title"] = "migrated value"
                }
            }
        }
        //if you changed `property` name, you must call `reanme Property`
        miggration.renameProperty(onType: "User", from: "currentUser", to: "isCurrentUser")
    }
)

let realm = try! Realm(configuration: configuration)
            
            
```

- add object

```swift
let configuration = Realm.Configuration(
                schemaVersion: 7,
                migrationBlock: { miggration, oldVersion in
                    
				//if you wanted to create object
        if oldVersion == 6 {
            miggration.enumerateObjects(ofType: "User") { (old, new) in
                let passport: MigrationObject = miggration.create("Passport", value: ["passportNumber": "migration passport Number"])
                new?["passport"] = passport
            }
        }
        
    

    }
)
    
let realm = try Realm(configuration: configuration)
```

- handle version, old, new

```swift
//handle old, new values with version numbers
let configuration = Realm.Configuration(
                schemaVersion: 7,
                migrationBlock: { miggration, oldVersion in
	
			//handle old, new values with version numbers
        miggration.enumerateObjects(ofType: "User") { (old, new) in
            if oldVersion == 5 {
                if old?["title"] == nil {
                    new?["title"] = "new migrated value"
                }
            }
        }
		}
)

let realm = try Realm(configuration: configuration)
```

# Entire Code

```swift
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
```