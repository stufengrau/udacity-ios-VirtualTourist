//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by heike on 24/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum getFlickrImagesResult {
    case success
    case failure
    case noImagesFound
}

class FlickrAPI {
    
    // MARK: Properties
    
    private var session = URLSession.shared
    // Number of photos per pin
    private let photosPerPage = 21
    private let maxFlickrResults = 4000
    
    // Upper Limit of Pages
    private var maxFlickrPages: Int { return maxFlickrResults / photosPerPage }
    
    var stack: CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    // Singleton
    static let shared = FlickrAPI()
    private init() {}
    
    // MARK: Network Requests
    
    // Get number of result pages from flickr for a pin
    func getFlickrImagePages(for pin: Pin, completionHandler: @escaping (getFlickrImagesResult) -> Void) {
        
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
            
            // Get image URLs from Flickr for a random page
            self.getFlickrImageURLs(pin, methodParameters, withPageNumber: self.getRandomPage(totalPages), completionHandler: completionHandler)
            
            }.resume()
        
    }
    
    // Get image URLs from Flickr for a specified page
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
            
            // Images found for location?
            if photosArray.count == 0 {
                completionHandler(.noImagesFound)
                return
            } else {
                
                self.stack.performBackgroundBatchOperation { (workerContext) in
                    // Create photo objects for each image in the flickr result
                    // Save the image url and link the photos to the pin
                    for photoDictionary in photosArray {
                        guard let imageURLString = photoDictionary[FlickrResponseKeys.MediumURL] as? String else {
                            completionHandler(.failure)
                            return
                        }
                        let photo = Photo(url: imageURLString, imageData: nil, context: workerContext)
                        photo.pin = pin
                    }
                    completionHandler(.success)
                }
            }
        }.resume()
        
    }
    
    // Get the image data for a specified URL
    func getFlickrImage(for url: String) {
        
        let imageURL = URL(string: url)

        session.dataTask(with: imageURL!) {data, _, _ in
            
            guard let data = data else {
                return
            }
            
            self.stack.performBackgroundBatchOperation { (workerContext) in
                // First the photo object itself was a parameter of the getFlickrImage method
                // but the lifetime of the object was to long and caused site effects
                // Therefore fetch the photo object for the specified URL
                // If pins are close enough to each other, their search radius can overlap and a
                // URL might not be unique, so the image data for all returned photo objects is set
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
                fetchRequest.predicate = NSPredicate(format: "url = %@", argumentArray: [url])
                if let photos = try? workerContext.fetch(fetchRequest) as! [Photo] {
                    for photo in photos {
                        photo.image = data
                    }
                }
            }
        }.resume()
        
    }
    
    
    // MARK: Helper functions
    
    // Return the parsed Result if no errors occured
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
    
    // Create Flickr URL from Parameters
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
    
    // Get a random page inside flickr results
    private func getRandomPage(_ totalPages: Int) -> Int {
        // If there is more than one page, ignore the last page
        // the last page may contain less then 'photosPerPage' Images
        var pages = totalPages
        if totalPages > 1 {
            pages = totalPages - 1
        }
        // Limit Pages to match upper limit of flickr results
        let maxPage = min(pages, maxFlickrPages)
        let randomPage = Int(arc4random_uniform(UInt32(maxPage))) + 1
        return randomPage
    }
}
