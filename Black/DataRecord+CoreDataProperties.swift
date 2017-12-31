//
//  DataRecord+CoreDataProperties.swift
//  Black
//
//  Created by Tjaz Hrovat on 28/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
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
