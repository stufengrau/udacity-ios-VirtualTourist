//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by heike on 20/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var deletionHint: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletionHintBottomConstraint: NSLayoutConstraint!
    
    var stack: CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set intital editing behaviour and add editButton to Navigation Bar
        setEditing(false, animated: true)
        navigationItem.rightBarButtonItem = editButtonItem
        // Hide deletion hint
        deletionHintBottomConstraint.constant -= deletionHint.bounds.size.height
        
        mapView.delegate = self
        
        // Set the Map region and span values to last state
        if let region = DefaultStore.shared.region {
            mapView.region = region
        }
        
        // Try to retrieve and add annotations to the map
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        if let pins = try? stack.context.fetch(fetchRequest) as! [Pin] {
            mapView.addAnnotations(pins.map({
                $0.makeAnnotation()
            }))
        }
        
        // Display an alert if no Flickr API Key is provided
        if FlickrAPI.FlickrAPIKey.APIKey == "" {
            showAlert("Please provide a Flickr API Key in the FlickrAPIKey.swift file")
        }
    }
    
    // MARK: Editing Mode
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        // Display deletion hint label when in editing mode
        UIView.animate(withDuration: 0.5) {
            self.deletionHintBottomConstraint.constant = editing ? 0 : -(self.deletionHint.bounds.size.height)
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: IBActions
    
    // Add annotation if long pressed on the map
    @IBAction func tappedOnMap(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            
            // Get the tapped location, which is a CGPoint
            let location = sender.location(in: mapView)
            // A CLLocationCoordinate2D is needed to set the coordinate for the annotation
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Save the pin in core data and add annotation to the map
            stack.performBackgroundBatchOperation { (workerContext) in
                _ = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, context: workerContext)
            }
            mapView.addAnnotation(annotation)
        }
    }
    
}

extension MapViewController {
    
    // MARK: MKMapViewDelegate
    
    // Create pin views with animated pin drop
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // Save region of the mapView when region changed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        DefaultStore.shared.region = mapView.region
    }
    
    // If a pin is tapped, show the photosViewController
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation else {
            assertionFailure("Annotation just get tapped and therefore should be present")
            return
        }
        
        // Deselect the annotation straightaway
        // otherwise a second tap on the same annotation won't work
        mapView.deselectAnnotation(annotation, animated: false)
        
        // Try to get the correct core data object for the tapped annotation
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        // Direct comparison of Double Values is not a good idea and even not working
        // So to find the corresponding object search in a small range of values
        // http://stackoverflow.com/questions/2026649/nspredicate-dont-work-with-double-values-f
        let epsilon = 0.000000001;
        let coordinate = annotation.coordinate
        let fetchPredicate = NSPredicate(format: "latitude > %lf AND latitude < %lf AND longitude > %lf AND longitude < %lf",
                                         coordinate.latitude - epsilon,  coordinate.latitude + epsilon,
                                         coordinate.longitude - epsilon, coordinate.longitude + epsilon)
        fetchRequest.predicate = fetchPredicate
        
        // Delete pin from map and core data if in edit mode
        // else transition to the photos view controller
        if let pins = try? stack.backgroundContext.fetch(fetchRequest) as! [NSManagedObject] {
            if let pin = pins.first {
                if isEditing {
                    stack.performBackgroundBatchOperation { $0.delete(pin) }
                    mapView.removeAnnotation(annotation)
                } else {
                    let vc = storyboard?.instantiateViewController(withIdentifier: "photosViewController") as! PhotosViewController
                    vc.pin = pin as? Pin
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
}

