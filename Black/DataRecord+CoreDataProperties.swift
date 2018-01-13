//
//  DataRecord+CoreDataProperties.swift
//  Black
//
//  Created by Tjaz Hrovat on 06/01/2018.
//  Copyright © 2018 Tjaz Hrovat. All rights reserved.
//
//

import Foundation
import CoreData


extension DataRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DataRecord> {
        return NSFetchRequest<DataRecord>(entityName: "DataRecord")
    }

    @NSManaged public var created: NSDate?

}
