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
    var insertPhotosAtIndexes: [IndexPath]!
    var deletePhotosAtIndexes: [IndexPath]!
    var selectedPhotos: [IndexPath]!
    var pin : Pin!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
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
        
        newCollectionButton.isEnabled = false
        collectionView.allowsMultipleSelection = true
        editMode = false
        
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
            getFlickrImagePages()
        }
    }
    
    @IBAction func collectionButton(_ sender: UIButton) {

        if editMode! {
            
            for photoIndex in selectedPhotos {
                let photo = fetchedResultsController?.object(at: photoIndex) as! Photo
                stack.context.delete(photo)
            }
            
            editMode = false
        } else {
            
            newCollectionButton.isEnabled = false
            
            if let allPhotosForPin = fetchedResultsController?.fetchedObjects {
                for photo in allPhotosForPin {
                    stack.context.delete(photo as! NSManagedObject)
                }
            }
            
            getFlickrImagePages()
        }
    }


    // MARK: Helper
    
    private func getFlickrImagePages () {
        FlickrAPI.shared.getFlickrImagePages(forPin: pin) { (result) in
            switch(result) {
            case .success:
                debugPrint("Retrieving images from flickr: Done.")
            case .failure:
                debugPrint("Retrieving images from flickr: Something went wrong.")
            case .noImagesFound:
                debugPrint("Sorry, no images found for that location.")
                DispatchQueue.main.async {
                    self.newCollectionButton.isEnabled = true
                }
            }
        }
    }

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
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fc = fetchedResultsController else { return 0 }
        return fc.sections![section].numberOfObjects
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get the photo
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! PhotosCollectionViewCell
        
        cell.activityIndicatorView.hidesWhenStopped = true
        

        if cell.isSelected {
            cell.photoImageView.alpha = 0.3
        } else {
            cell.photoImageView.alpha = 1.0
        }
        
        if let imageData = photo.image {
            newCollectionButton.isEnabled = true
            cell.activityIndicatorView.stopAnimating()
            cell.photoImageView.image = UIImage(data: imageData)
        } else {
            cell.photoImageView.image = nil
            cell.backgroundColor = UIColor.gray
            cell.activityIndicatorView.startAnimating()
            FlickrAPI.shared.getFlickrImage(for: photo)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotosCollectionViewCell
        cell.photoImageView.alpha = 0.3
        selectedPhotos.append(indexPath)
        editMode = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotosCollectionViewCell
        cell.photoImageView.alpha = 1.0
        if let index = selectedPhotos.index(of: indexPath) {
            selectedPhotos.remove(at: index)
        }
        if selectedPhotos.count == 0 {
            editMode = false
        }
    }
    
}

extension PhotosViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertPhotosAtIndexes = [IndexPath]()
        deletePhotosAtIndexes = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .insert:
            insertPhotosAtIndexes.append(newIndexPath!)
        case .delete:
            deletePhotosAtIndexes.append(indexPath!)
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            assertionFailure()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        debugPrint("did change content")
        if insertPhotosAtIndexes.count > 0 {
            collectionView.insertItems(at: insertPhotosAtIndexes)
        }
        if deletePhotosAtIndexes.count > 0 {
            collectionView.deleteItems(at: deletePhotosAtIndexes)
        }
    }
}
