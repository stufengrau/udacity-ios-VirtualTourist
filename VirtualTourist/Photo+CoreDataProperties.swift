//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by heike on 26/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var url: String?
    @NSManaged public var image: Data?
    @NSManaged public var pin: Pin?

}
