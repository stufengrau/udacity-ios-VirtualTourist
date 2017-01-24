//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by heike on 23/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import Foundation
import CoreData
import MapKit


public class Pin: NSManagedObject {
    
    // MARK: Initializer
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
    func makeAnnotation() -> MKAnnotation {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        return annotation
    }
}
