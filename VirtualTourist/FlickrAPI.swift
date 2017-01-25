//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by heike on 24/01/2017.
//  Copyright © 2017 stufengrau. All rights reserved.
//

import Foundation

enum getFlickrImagesResult {
    case success
    case failure
    case noImagesFound
}

class FlickrAPI {
    
    // MARK: Properties
    
    private var session = URLSession.shared
    
    // Singleton
    static let shared = FlickrAPI()
    private init() {}
    
    // MARK: Network Requests
    
    // Get images from flickr for a pin
    func getFlickrImages(forLatitude lat: Double, andLongitude long: Double,
                         completionHandler: @escaping (getFlickrImagesResult) -> Void) {
        
        let methodParameters = [
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.APIKey: FlickrAPI.FlickrAPIKey.APIKey,
            FlickrParameterKeys.BoundingBox: self.bboxString(latitude: lat, longitude: long),
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback
        ]
        
        let request = NSMutableURLRequest(url: flickrURLFromParameters(methodParameters))
        
        session.dataTask(with: request as URLRequest) { data, response, error in
            
            guard error == nil else {
                completionHandler(.failure)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode >= 200 && statusCode <= 299 else {
                    completionHandler(.failure)
                    return
            }
            
            guard let parsedResult = self.convertData(data) as? [String: AnyObject] else {
                completionHandler(.failure)
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[FlickrResponseKeys.Status] as? String,
                stat == FlickrResponseValues.OKStatus else {
                    completionHandler(.failure)
                    return
            }
            
            guard let photosDictionary = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject],
                let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                    completionHandler(.failure)
                    return
            }
            
            debugPrint(photosArray.first!)
            
            completionHandler(.success)
            
            }.resume()
        
    }
    
    
    // MARK: Helper functions
    
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
