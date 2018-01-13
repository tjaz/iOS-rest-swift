//
//  JavaDeveloper+CoreDataProperties.swift
//  Black
//
//  Created by Tjaz Hrovat on 06/01/2018.
//  Copyright © 2018 Tjaz Hrovat. All rights reserved.
//
//

import Foundation
import CoreData


extension JavaDeveloper {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JavaDeveloper> {
        return NSFetchRequest<JavaDeveloper>(entityName: "JavaDeveloper")
    }

    @NSManaged public var username: String?
    @NSManaged public var avatar: NSData?
    @NSManaged public var registered: NSDate?
    @NSManaged public var url: URL?

}
