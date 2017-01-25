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
    
    var doneButton: UIBarButtonItem?
    var editButton: UIBarButtonItem?
    
    var stack: CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    var editMode: Bool! {
        didSet {
            if editMode! {
                navigationItem.rightBarButtonItem = doneButton
                deletionHint.isHidden = false
                mapView.frame.origin.y -= deletionHint.bounds.size.height
            } else {
                navigationItem.rightBarButtonItem = editButton
                deletionHint.isHidden = true
                mapView.frame.origin.y += deletionHint.bounds.size.height
            }
        }
    }
    
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toggleEditMode(_:)))
        editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleEditMode(_:)))
        
        editMode = false
        
        mapView.delegate = self
        
        // if the map region was saved before, set it to last values
        if let region = DefaultStore.shared.region {
            mapView.region = region
        }
        
        // try to retrieve and add annotations to the map
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        if let pins = try? stack.context.fetch(fetchRequest) as! [Pin] {
            mapView.addAnnotations(pins.map({
                $0.makeAnnotation()
            }))
        }
    }
    
    @IBAction func tappedOnMap(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            
            // Get the tapped location, which is a CGPoint
            let location = sender.location(in: mapView)
            // A CLLocationCoordinate2D is needed to set the coordinate for the annotation
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // save the pin in core data and add annotation to the map
            _ = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, context: stack.context)
            mapView.addAnnotation(annotation)
        }
    }
    
    // enable/disable edit mode to delete pins
    func toggleEditMode(_ sender: UIBarButtonItem) {
        editMode = !editMode
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
        
        // Direct comparison of Double Values is not a good idea and even not working
        // So to find the corresponding object search in a small range of values
        // http://stackoverflow.com/questions/2026649/nspredicate-dont-work-with-double-values-f
        let epsilon = 0.000000001;
        let coordinate = annotation.coordinate
        let fetchPredicate = NSPredicate(format: "latitude > %lf AND latitude < %lf AND longitude > %lf AND longitude < %lf",
                                         coordinate.latitude - epsilon,  coordinate.latitude + epsilon,
                                         coordinate.longitude - epsilon, coordinate.longitude + epsilon)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.predicate = fetchPredicate
        
        // TODO: Work in progress ... eventually refactor this
        if let pins = try? stack.context.fetch(fetchRequest) as! [NSManagedObject] {
            if let pin = pins.first {
                if editMode! {
                    stack.context.delete(pin)
                    mapView.removeAnnotation(annotation)
                } else {
                    let vc = storyboard?.instantiateViewController(withIdentifier: "photosViewController") as! PhotosViewController
                    vc.pin = pin as? Pin
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    // Save region of the mapView when region changed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        DefaultStore.shared.region = mapView.region
    }
    
}

