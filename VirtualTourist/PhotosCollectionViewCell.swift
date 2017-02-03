//
//  PhotosCollectionViewCell.swift
//  VirtualTourist
//
//  Created by heike on 30/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import UIKit

class PhotosCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override var isSelected: Bool {
        didSet {
            alpha = isSelected ? 0.5 : 1.0
        }
    }

    func configureCell(image: Data?) {
        
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
