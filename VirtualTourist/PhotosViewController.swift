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
    
    
    // MARK: Properties
    
    let reuseIdentifier = "photo"
    let spanDelta = 0.02
    var insertPhotosAtIndexes: [IndexPath]!
    var deletePhotosAtIndexes: [IndexPath]!
    var selectedPhotos: [IndexPath]!
    var pin: Pin!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImagesFoundLabel: UILabel!
    
    // Edit Mode to delete selected pins
    // or renew entire collection
    var editMode: Bool! {
        didSet {
            if editMode! {
                newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
            } else {
                newCollectionButton.setTitle("New Collection", for: .normal)
                selectedPhotos = [IndexPath]()
            }
        }
    }
    
    var stack: CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    var fetchRequest: NSFetchRequest<NSFetchRequestResult>!
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and reload the data
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView.reloadData()
        }
    }
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            try? fc.performFetch()
        }
    }
    
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup map view with pin
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        mapView.addAnnotation(annotation)
        mapView.region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpanMake(spanDelta, spanDelta))
        
        newCollectionButton.isEnabled = false
        noImagesFoundLabel.isHidden = true
        collectionView.allowsMultipleSelection = true
        editMode = false
        
        setGridLayout(view.frame.size)
        
        // Fetch request for all photos for a specific pin
        fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin!])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        
        // Fetched Results Controller in main context to notify about changes to core data objects
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // If pin has no images yet, get URLs from Flickr
        if let fetchResult = try? stack.backgroundContext.fetch(fetchRequest) as! [Photo] {
            if fetchResult.count == 0 {
                getFlickrImagePages()
            }
        }
    }
    
    // MARK: IBActions
    
    // Button to delete selected pins or renew entire collection
    @IBAction func collectionButton(_ sender: UIButton) {
        
        if editMode! {
            // Delete selected photos
            let photosToDelete = selectedPhotos
            stack.performBackgroundBatchOperation { (workerContext) in
                if let photos = try? workerContext.fetch(self.fetchRequest) as! [Photo] {
                    for photoIndex in photosToDelete! {
                        workerContext.delete(photos[photoIndex.row])
                    }
                }
            }
            editMode = false
        } else {
            
            newCollectionButton.isEnabled = false
            
            // Delete photos of previous collection
            stack.performBackgroundBatchOperation { (workerContext) in
                if let allPhotosForPin = try? workerContext.fetch(self.fetchRequest) as! [NSManagedObject] {
                    for photo in allPhotosForPin {
                        workerContext.delete(photo)
                    }
                }
            }
            
            // Get URLs for new collection
            getFlickrImagePages()
        }
    }
    
    
    // MARK: Helper
    
    // Try to get URLs for a new collection of photos for specified pin
    private func getFlickrImagePages () {
        FlickrAPI.shared.getFlickrImagePages(for: pin) { (result) in
            switch(result) {
            case .success:
                DispatchQueue.main.async {
                    self.noImagesFoundLabel.isHidden = true
                }
            case .failure:
                DispatchQueue.main.async {
                    self.showAlert("Network failure. Please try again later.")
                    self.newCollectionButton.isEnabled = true
                }
            case .noImagesFound:
                DispatchQueue.main.async {
                    self.noImagesFoundLabel.isHidden = false
                    self.newCollectionButton.isEnabled = true
                }
            }
        }
    }
    
    // Display an alert message
    private func showAlert(_ errormessage: String) {
        let alertController = UIAlertController(title: "", message: errormessage, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alertController.addAction(dismissAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Set Flow layout for collection view
    private func setGridLayout(_ size: CGSize) {
        
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
    
    // MARK: UICollectionViewDataSource protocol
    
    // Tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fetchResult = try? stack.backgroundContext.fetch(fetchRequest) as! [Photo] else { return 0 }
        return fetchResult.count
    }
    
    // Make a cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to the storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! PhotosCollectionViewCell
        
        // Get the photo object
        guard let photos = try? stack.backgroundContext.fetch(fetchRequest) as! [Photo] else { return cell }
        let photo = photos[indexPath.row]
        
        cell.configureCell(image: photo.image)
        
        // If there is no image data yet, get the Image
        if photo.image == nil {
            if let url = photo.url {
                FlickrAPI.shared.getFlickrImage(for: url)
            }
        } else {
            // Since the images are only loaded for the visible cells
            // the newCollectionButton is enabled as soon as one image has loaded
            newCollectionButton.isEnabled = true
        }
        
        return cell
    }
    
    // Select an image
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedPhotos.append(indexPath)
        editMode = true
    }
    
    // Deselect an image
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let index = selectedPhotos.index(of: indexPath) {
            selectedPhotos.remove(at: index)
        }
        // If no more photo is selected, editMode is false -> nothing to delete
        if selectedPhotos.count == 0 {
            editMode = false
        }
    }
    
}

extension PhotosViewController: NSFetchedResultsControllerDelegate {
    
    // MARK: NSFetchedResultsControllerDelegate protocol
    
    // Core Data Object will change content
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertPhotosAtIndexes = [IndexPath]()
        deletePhotosAtIndexes = [IndexPath]()
    }
    
    // Notification about changes to core data objects
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .insert:
            // Memorize photos to insert
            insertPhotosAtIndexes.append(newIndexPath!)
        case .delete:
            // Memorize photos to delete
            deletePhotosAtIndexes.append(indexPath!)
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            assertionFailure()
        }
    }
    
    // Core Data Object did change content
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Bulk insert
        // otherwise there will be a conflict with the number of objects in the collection view section
        if insertPhotosAtIndexes.count > 0 {
            collectionView.insertItems(at: insertPhotosAtIndexes)
        }
        // Bulk delete
        // otherwise there will be a conflict with the number of objects in the collection view section
        if deletePhotosAtIndexes.count > 0 {
            collectionView.deleteItems(at: deletePhotosAtIndexes)
        }
    }
}
