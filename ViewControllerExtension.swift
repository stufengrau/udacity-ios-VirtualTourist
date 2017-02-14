//
//  ViewControllerExtension.swift
//  OnTheMap
//
//  Created by heike on 30/12/2016.
//  Copyright © 2016 stufengrau. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    // Show Alert function for all View Controllers
    func showAlert(_ errormessage: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "", message: errormessage, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alertController.addAction(dismissAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
}
