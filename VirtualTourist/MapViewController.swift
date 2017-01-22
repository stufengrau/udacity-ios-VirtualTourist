//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by heike on 20/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    // MARK: Properties
    
    @IBOutlet weak var deletionHint: UILabel!
    @IBOutlet weak var mapView: MKMapView!

    var doneButton: UIBarButtonItem?
    var editButton: UIBarButtonItem?
    
    var editMode: Bool! {
        didSet {
            if editMode! {
                navigationItem.rightBarButtonItem = doneButton
                deletionHint.isHidden = false
            } else {
                navigationItem.rightBarButtonItem = editButton
                deletionHint.isHidden = true
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
    }
    
    @IBAction func tappedOnMap(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            
            // Get the tapped location, which is a CGPoint
            let location = sender.location(in: mapView)
            // A CLLocationCoordinate2D is needed to set the coordinate for the annotation
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            // Add annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    func toggleEditMode(_ sender: UIBarButtonItem) {
        editMode = !editMode
    }
    
    // MARK: MKMapViewDelegate
    
    // Animate new pin drop
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
        if editMode! {
            mapView.removeAnnotation(view.annotation!)
        } else {
            let vc = storyboard?.instantiateViewController(withIdentifier: "photosViewController")
            navigationController?.pushViewController(vc!, animated: true)
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}

