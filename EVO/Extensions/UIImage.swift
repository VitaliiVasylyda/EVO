//
//  UIImage.swift
//  EVO
//
//  Created by Vitalii Vasylyda on 11/26/18.
//  Copyright © 2018 VitaliiVasylyda. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    func roundedImage(cornerRadius: CGFloat) -> UIImage? {
        return roundedImage(cornerRadius: cornerRadius, backgroundImage: nil, margin: 0)
    }
    
    func roundedImage(cornerRadius: CGFloat, backgroundImage: UIImage?, margin: CGFloat?) -> UIImage? {
        return roundedImage(size: self.size, cornerRadius: cornerRadius, backgroundImage: backgroundImage, margin: margin)
    }
    
    func roundedImage(size: CGSize, cornerRadius: CGFloat, backgroundImage: UIImage?, margin: CGFloat?) -> UIImage? {
        assert(!Thread.isMainThread, "executing heavy image task in main thread")
        return autoreleasepool(invoking: { () -> UIImage? in
            // Begin a new image that will be the new image with the rounded corners
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            guard let context = UIGraphicsGetCurrentContext() else {
                return nil
            }
            
            context.interpolationQuality = .high
            
            // Add a clip before drawing anything, in the shape of an rounded rect
            let rect = CGRect(x: 0, y:0, width: size.width, height: size.height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.addClip()
            
            // Draw image
            self.draw(in: rect)
            
            // Get the image
            var roundedImage = UIGraphicsGetImageFromCurrentImageContext()
            
            // Lets forget about that we were drawing
            UIGraphicsEndImageContext()
            
            if let background = backgroundImage, let margin = margin, margin > 0 {
                // Begin a new image that will be the new image with the rounded corners
                UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width + 2 * margin, height: size.height + 2 * margin), false, 0.0)
                
                guard let context = UIGraphicsGetCurrentContext() else {
                    return roundedImage
                }
                
                context.interpolationQuality = .high
                
                // Add a clip before drawing anything, in the shape of an rounded rect
                let rect = CGRect(x: 0, y: 0, width: size.width + 2 * margin, height: size.height + 2 * margin)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
                path.addClip()
                
                background.draw(in: rect)
                roundedImage?.draw(in: CGRect(x: margin, y: margin, width: size.width, height: size.height))
                
                // Get the image, here setting the UIImageView image
                roundedImage =  UIGraphicsGetImageFromCurrentImageContext()
                
                // Lets forget about that we were drawing
                UIGraphicsEndImageContext()
            }
            
            return roundedImage
        })
    }
    
    func thumbnailImage(size: CGSize, quality: CGInterpolationQuality, keepAspectRatio: Bool) -> UIImage? {
        assert(!Thread.isMainThread, "executing heavy image task in main thread")
        return autoreleasepool(invoking: { () -> UIImage? in
            if size.width * size.height == 0 {
                return nil
            }
            
            var scaledImage: UIImage? = nil
            
            UIGraphicsBeginImageContext(size)
            
            guard let context = UIGraphicsGetCurrentContext() else {
                return nil
            }
            
            context.interpolationQuality = quality
            
            if (!keepAspectRatio)
            {
                let rect = CGRect(x: 0, y:0, width: size.width, height: size.height)
                context.draw(self.cgImage!, in: rect)
            }
            else
            {
                let horizontalScaleFactor  = size.width / self.size.width
                let verticalScaleFactor = size.height / self.size.height
                
                let scaleFactor = max(horizontalScaleFactor, verticalScaleFactor)
                
                let rect = CGRect(x: (size.width - self.size.width * scaleFactor) / 2,
                                  y: (size.height - self.size.height * scaleFactor) / 2,
                                  width: self.size.width * scaleFactor, height: self.size.height * scaleFactor)
                
                self.draw(in: rect)
            }
            
            scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return scaledImage
        })
    }
}
