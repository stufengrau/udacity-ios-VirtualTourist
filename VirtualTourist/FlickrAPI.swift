//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by heike on 24/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import Foundation
import UIKit

enum getFlickrImagesResult {
    case success
    case failure
    case noImagesFound
}

class FlickrAPI {
    
    // MARK: Properties
    
    private var session = URLSession.shared
    private let photosPerPage = 21
    
    var stack: CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    // Singleton
    static let shared = FlickrAPI()
    private init() {}
    
    // MARK: Network Requests
    
    // Get images from flickr for a pin
    func getFlickrImagePages(forPin pin: Pin, completionHandler: @escaping (getFlickrImagesResult) -> Void) {
        
        let methodParameters = [
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.APIKey: FlickrAPI.FlickrAPIKey.APIKey,
            FlickrParameterKeys.BoundingBox: self.bboxString(latitude: pin.latitude, longitude: pin.longitude),
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback,
            FlickrParameterKeys.PerPage: String(photosPerPage)
        ]
        
        let request = NSMutableURLRequest(url: flickrURLFromParameters(methodParameters))
        
        session.dataTask(with: request as URLRequest) { data, response, error in
            
            guard let parsedResult = self.getResult(data: data, response: response, error: error) else {
                completionHandler(.failure)
                return
            }
            
            guard let photosDictionary = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject],
                let totalPages = photosDictionary[FlickrResponseKeys.Pages] as? Int else {
                    completionHandler(.failure)
                    return
            }
            
            debugPrint("totalPages: \(totalPages)")
            
            // pick a random page!
            let randomPage = Int(arc4random_uniform(UInt32(totalPages))) + 1
            debugPrint("Random Page: \(randomPage)")
            
            self.getFlickrImageURLs(pin, methodParameters, withPageNumber: randomPage, completionHandler: completionHandler)
            
            
            }.resume()
        
    }
    
    private func getFlickrImageURLs(_ pin: Pin, _ methodParameters: [String: String], withPageNumber: Int,
                                                completionHandler: @escaping (getFlickrImagesResult) -> Void) {
        
        // add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[FlickrParameterKeys.Page] = String(withPageNumber)
        
        let request = URLRequest(url: flickrURLFromParameters(methodParametersWithPageNumber))
        
        session.dataTask(with: request) { (data, response, error) in

            guard let parsedResult = self.getResult(data: data, response: response, error: error) else {
                completionHandler(.failure)
                return
            }
            
            guard let photosDictionary = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject],
                let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    completionHandler(.failure)
                    return
            }
            
            if photosArray.count == 0 {
                completionHandler(.noImagesFound)
                return
            } else {
                
                self.stack.performBackgroundBatchOperation { (workerContext) in
                    
                    for photoDictionary in photosArray {
                        guard let imageURLString = photoDictionary[FlickrResponseKeys.MediumURL] as? String else {
                            completionHandler(.failure)
                            return
                        }
                        let photo = Photo(url: imageURLString, imageData: nil, context: self.stack.context)
                        photo.pin = pin
                        debugPrint(imageURLString)
                    }
                    print("==== finished background operation ====")
                    completionHandler(.success)
                }
            }
        }.resume()
        
    }
    
    func getFlickrImage(for photo: Photo) {
        
        let imageURL = URL(string: photo.url!)

        session.dataTask(with: imageURL!) {_,_,_ in 
            photo.image = try? Data(contentsOf: imageURL!)
        }.resume()
        
        
    }
    
    
    // MARK: Helper functions
    
    private func getResult(data: Data?, response: URLResponse?, error: Error?) -> [String: AnyObject]? {
        
        guard error == nil else {
            return nil
        }
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
            return nil
        }
        
        guard let parsedResult = self.convertData(data) as? [String: AnyObject] else {
            return nil
        }
        
        guard let stat = parsedResult[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
            return nil
        }
        
        return parsedResult
    }
    
    // Create URL from Parameters
    private func flickrURLFromParameters(_ parameters: [String:String]) -> URL {
        
        var components = URLComponents()
        components.scheme = FlickrURL.APIScheme
        components.host = FlickrURL.APIHost
        components.path = FlickrURL.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    // Given raw JSON, return a usable Foundation object
    private func convertData(_ data: Data?) -> AnyObject? {
        
        guard let data = data else {
            return nil
        }
        
        return try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
    }
    
    // Create bbox string to search in a small area around the given latitude and longitude
    private func bboxString(latitude: Double, longitude: Double) -> String {
        let minimumLon = max(longitude - BBox.SearchBBoxHalfWidth, BBox.SearchLonRange.0)
        let minimumLat = max(latitude - BBox.SearchBBoxHalfHeight, BBox.SearchLatRange.0)
        let maximumLon = min(longitude + BBox.SearchBBoxHalfWidth, BBox.SearchLonRange.1)
        let maximumLat = min(latitude + BBox.SearchBBoxHalfHeight, BBox.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}
