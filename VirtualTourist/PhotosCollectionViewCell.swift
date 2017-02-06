//
//  PhotosCollectionViewCell.swift
//  VirtualTourist
//
//  Created by heike on 30/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import UIKit

class PhotosCollectionViewCell: UICollectionViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override var isSelected: Bool {
        didSet {
            alpha = isSelected ? 0.5 : 1.0
        }
    }
    
    // MARK: Cell Configuration

    func configureCell(image: Data?) {
        
        // If there is no image data yet, start an animation
        if let imageData = image {
            activityIndicatorView.stopAnimating()
            photoImageView.image = UIImage(data: imageData)
        } else {
            photoImageView.image = nil
            backgroundColor = UIColor.gray
            activityIndicatorView.startAnimating()
        }
    }
}
