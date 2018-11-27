//
//  ImageProvider.swift
//  EVO
//
//  Created by Vitalii Vasylyda on 11/26/18.
//  Copyright © 2018 VitaliiVasylyda. All rights reserved.
//

import Foundation
import UIKit

class ImageProvider {
    
    enum PrepareType {
        case round(CGFloat)
        case thumbnail(CGFloat, CGFloat)
        case custom(((_ image: UIImage) -> UIImage?))
        
        var preparation: ((_ image: UIImage) -> UIImage?) {
            switch self {
            case .round(let diameter):
                return { image in
                    
                    let size = diameter
                    let squareImage = image.thumbnailImage(size: CGSize(width: size, height: size), quality: .high, keepAspectRatio: true)
                    return squareImage?.roundedImage(cornerRadius: image.size.width/2.0)
                }
            case .thumbnail(let width, let height):
                return { image in
                    if image.size.width <= width || image.size.height <= height {
                        return image
                    }
                    
                    return image.thumbnailImage(size: CGSize(width: width, height: height), quality: .high, keepAspectRatio: true)
                }
            case .custom (let closure):
                return closure
            }
        }
        
        func cacheURL(_ url: URL) -> URL? {
            switch self {
            case .round(let diameter):
                return url.appendingPathComponent("round-\(diameter)")
            case .thumbnail(let width, let height):
                return url.appendingPathComponent("thumbnail-\(width)x\(height)")
            case .custom:
                return nil
            }
        }
    }
    
    let session: URLSession
    let documentsDirectory: String
    
    init() {
        /*
         let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "com.hive.networking.background")
         session = URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: .main)
         */
        session = URLSession(configuration: .default)
        documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    private var images = [URL: UIImage]()
    
    var placeholder: UIImage?
    var prepareType: PrepareType?
    
    // load images on demand
    /*
     1. return image, if already loaded
     2. if not, check the cache
     3. if not, load it in background
     4. if prepare closure is available, call it and store prepared image
     5. else, store loaded image in cache and in memory
     6. return image in main thread
     */
    func loadImage(url: URL, completion: @escaping (_ image: UIImage) -> Void) -> UIImage? {
        
        let cacheURL = prepareType?.cacheURL(url) ?? url
        
        if let image = images[cacheURL] {
            return image
        } else if let image = Cache.shared.cachedImage(url: cacheURL) {
            images[cacheURL] = image
            return image
        } else {
            self.images[cacheURL] = placeholder
            let request = URLRequest(url: url)
            
            session.dataTask(with: request, completionHandler: { (data, response, error) in
                if error == nil, let data = data, let image = UIImage(data: data) {
                    if let closure = self.prepareType?.preparation, let processedImage = closure(image) {
                        self.images[cacheURL] = processedImage
                        Cache.shared.cache(image: processedImage, url: cacheURL)
                        DispatchQueue.main.async {
                            completion(processedImage)
                        }
                    } else {
                        self.images[cacheURL] = image
                        Cache.shared.cache(imageData: data, url: cacheURL)
                        DispatchQueue.main.async {
                            completion(image)
                        }
                    }
                } else if let placeholder = self.placeholder {
                    DispatchQueue.main.async {
                        completion(placeholder)
                    }
                }
            }).resume()
        }
        
        return nil
    }
    
}
