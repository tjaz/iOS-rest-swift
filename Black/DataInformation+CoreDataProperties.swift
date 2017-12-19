//
//  DataInformation+CoreDataProperties.swift
//  Black
//
//  Created by Tjaz Hrovat on 15/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//
//

import Foundation
import CoreData


extension DataInformation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DataInformation> {
        return NSFetchRequest<DataInformation>(entityName: "DataInformation")
    }

    @NSManaged public var creation: NSDate?

}
