//
//  Developer+CoreDataProperties.swift
//  Black
//
//  Created by Tjaz Hrovat on 02/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//
//

import Foundation
import CoreData


extension Developer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Developer> {
        return NSFetchRequest<Developer>(entityName: "Developer")
    }

    @NSManaged public var url: URL?
    @NSManaged public var username: String?
    @NSManaged public var avatar: NSData?
    @NSManaged public var created: NSDate?

}
