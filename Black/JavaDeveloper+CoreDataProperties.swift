//
//  JavaDeveloper+CoreDataProperties.swift
//  GithubKit
//
//  Created by Tjaz Hrovat on 14/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//
//

import Foundation
import CoreData


extension JavaDeveloper {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JavaDeveloper> {
        return NSFetchRequest<JavaDeveloper>(entityName: "JavaDeveloper")
    }

    @NSManaged public var url: URL?
    @NSManaged public var avatar: NSData?
    @NSManaged public var username: String?
    @NSManaged public var registered: NSDate?

}
