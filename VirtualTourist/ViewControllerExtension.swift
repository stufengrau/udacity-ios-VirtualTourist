//
//  ViewControllerExtension.swift
//  VirtualTourist
//
//  Created by heike on 08/02/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    // Show Alert function for all View Controllers
    func showAlert(_ errormessage: String) {
            let alertController = UIAlertController(title: "", message: errormessage, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alertController.addAction(dismissAction)
            self.present(alertController, animated: true, completion: nil)
    }
    
}
