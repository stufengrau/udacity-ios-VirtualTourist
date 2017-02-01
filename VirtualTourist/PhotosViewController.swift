//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by heike on 20/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotosViewController: UIViewController, MKMapViewDelegate  {
    
    let reuseIdentifier = "photo"
    var indexArray: [IndexPath]!
    var pin : Pin!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    
    var stack: CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the data
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView.reloadData()
        }
    }
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        mapView.addAnnotation(annotation)
        mapView.region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpanMake(0.05, 0.05))
        
        setGridLayout(view.frame.size)
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let pred = NSPredicate(format: "pin = %@", argumentArray: [pin!])
        fr.predicate = pred

        
        fr.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if fetchedResultsController!.sections![0].numberOfObjects == 0 {
            FlickrAPI.shared.getFlickrImages(forPin: pin) { (result) in
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

    
    // MARK: Helper
    
    func setGridLayout(_ size: CGSize) {
        
        let spacing: CGFloat = 3.0
        let numberPortrait: CGFloat = 3.0
        let numberLandscape: CGFloat = 5.0
        let frameWidth = size.width
        let frameHeight = size.height
        var dimension: CGFloat
        
        // Set grid layout based on orientation.
        if (frameHeight > frameWidth) {
            dimension = (frameWidth - ((numberPortrait - 1) * spacing)) / numberPortrait
        } else {
            dimension = (frameWidth - ((numberLandscape - 1) * spacing)) / numberLandscape
        }
        
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }

}

extension PhotosViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fc = fetchedResultsController else { return 0 }
        debugPrint("fetchedResultsController ok")
        debugPrint("number of Objects: \(fc.sections![section].numberOfObjects)")
        return fc.sections![section].numberOfObjects
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        debugPrint("make cell")
        
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! PhotosCollectionViewCell
        
        cell.backgroundColor = UIColor.blue
        
        return cell
    }
    
}

extension PhotosViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        debugPrint("will change content")
        indexArray = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            debugPrint("begin insert")
            debugPrint("newIndexPath: \(newIndexPath)")
            indexArray.append(newIndexPath!)
        case .delete:
            debugPrint("delete")
        case .update:
            debugPrint("update")
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            debugPrint("move")

        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        debugPrint("did change content")
        collectionView.insertItems(at: indexArray)
    }
}
