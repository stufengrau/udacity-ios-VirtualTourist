//
//  DefaultStore.swift
//  VirtualTourist
//
//  Created by heike on 23/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import Foundation
import MapKit

class DefaultStore {
    
    // MARK: Properties
    
    private let regionLatitudeKey = "regionLatitude"
    private let regionLongitudeKey = "regionLongitude"
    private let spanLatitudeDeltaKey = "spanLatitudeDelta"
    private let spanLongitudeDeltaKey = "spanLongitudeDelta"
    private let regionIsSetKey = "regionIsSet"
    
    // Persist the last map region and span in UserDefaults
    var region: MKCoordinateRegion? {
        get {
            // Check if map region/span is set yet
            if UserDefaults.standard.bool(forKey: regionIsSetKey) {
                return MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: UserDefaults.standard.double(forKey: regionLatitudeKey),
                        longitude: UserDefaults.standard.double(forKey: regionLongitudeKey)
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: UserDefaults.standard.double(forKey: spanLatitudeDeltaKey),
                        longitudeDelta: UserDefaults.standard.double(forKey: spanLongitudeDeltaKey)
                    )
                )
            }
            return nil
        }
        set {
            if let regionValue = newValue {
                UserDefaults.standard.set(regionValue.center.latitude, forKey: regionLatitudeKey)
                UserDefaults.standard.set(regionValue.center.longitude, forKey: regionLongitudeKey)
                UserDefaults.standard.set(regionValue.span.latitudeDelta, forKey: spanLatitudeDeltaKey)
                UserDefaults.standard.set(regionValue.span.longitudeDelta, forKey: spanLongitudeDeltaKey)
                UserDefaults.standard.set(true, forKey: regionIsSetKey)
            } else {
                UserDefaults.standard.set(false, forKey: regionIsSetKey)
            }
        }
    }
    
    // Singelton
    static let shared = DefaultStore()
    private init() {}
    
    
}
