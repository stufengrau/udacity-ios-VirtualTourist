//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by heike on 26/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {
    
    // MARK: Initializer
    
    convenience init(url: String, imageData: NSData, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.url = url
            self.image = imageData
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
