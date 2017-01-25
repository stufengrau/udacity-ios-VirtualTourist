//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by heike on 20/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import UIKit
import MapKit

class PhotosViewController: UIViewController, MKMapViewDelegate {
    
    var pin : Pin!
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func getImagesFromFlickr(_ sender: UIButton) {
        FlickrAPI.shared.getFlickrImages(forLatitude: pin.latitude, andLongitude: pin.longitude) { (result) in
            switch(result) {
            case .success:
                debugPrint("Retrieving images from flickr: Done.")
            case .failure:
                debugPrint("Retrieving images from flickr: Something went wrong.")
            case .noImagesFound:
                debugPrint("Sorry, no images found for that location.")
            }
        }
    }
    
}
