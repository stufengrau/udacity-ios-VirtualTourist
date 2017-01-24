//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by heike on 23/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin");
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double

}
