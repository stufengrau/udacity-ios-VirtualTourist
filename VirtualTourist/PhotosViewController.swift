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
    var pin: Pin!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImagesFoundLabel: UILabel!
    
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

        newCollectionButton.isEnabled = false
        noImagesFoundLabel.isHidden = true
        collectionView.allowsMultipleSelection = true
        editMode = false
        
        setGridLayout(view.frame.size)
        
        fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin!])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        debugPrint("View will appear")
        // TODO:
        let fr = try? stack.backgroundContext.fetch(fetchRequest) as! [Photo]
        if fr?.count == 0 {
            getFlickrImagePages()
        }
    }
    
    @IBAction func collectionButton(_ sender: UIButton) {

        if editMode! {
            let photosToDelete = selectedPhotos
            self.stack.performBackgroundBatchOperation { (workerContext) in
                if let photos = try? workerContext.fetch(self.fetchRequest) as! [Photo] {
                    for photoIndex in photosToDelete! {
                        workerContext.delete(photos[photoIndex.row])
                    }
                }
            }
            editMode = false
        } else {
            
            newCollectionButton.isEnabled = false
        
            self.stack.performBackgroundBatchOperation { (workerContext) in
                if let allPhotosForPin = try? workerContext.fetch(self.fetchRequest) as! [NSManagedObject] {
                    for photo in allPhotosForPin {
                        workerContext.delete(photo)
                    }
                }
            }
            
            getFlickrImagePages()
        }
    }


    // MARK: Helper
    
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
    
    private func showAlert(_ errormessage: String) {
            let alertController = UIAlertController(title: "", message: errormessage, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alertController.addAction(dismissAction)
            self.present(alertController, animated: true, completion: nil)
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
        //guard let fc = fetchedResultsController else { return 0 }
        let fr = try? stack.backgroundContext.fetch(fetchRequest) as! [Photo]
        return fr?.count ?? 0
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get the photo
        let photos = try? stack.backgroundContext.fetch(fetchRequest) as! [Photo]
        let photo = photos![indexPath.row]
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! PhotosCollectionViewCell
        
        cell.configureCell(image: photo.image)
        
        if (photo.image != nil) {
            newCollectionButton.isEnabled = true
        } else {
            FlickrAPI.shared.getFlickrImage(for: photo.url!)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedPhotos.append(indexPath)
        editMode = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
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
        if insertPhotosAtIndexes.count > 0 {
            collectionView.insertItems(at: insertPhotosAtIndexes)
        }
        if deletePhotosAtIndexes.count > 0 {
            collectionView.deleteItems(at: deletePhotosAtIndexes)
        }
    }
}
