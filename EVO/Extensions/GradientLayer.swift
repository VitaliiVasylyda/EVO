//
//  GradientLayer.swift
//  EVO
//
//  Created by Vitalii Vasylyda on 11/23/18.
//  Copyright © 2018 VitaliiVasylyda. All rights reserved.
//

import UIKit

extension CAGradientLayer {
    
    convenience init(frame: CGRect, colors: [UIColor]) {
        self.init()
        self.frame = frame
        self.colors = []
        
        for color in colors {
            self.colors?.append(color.cgColor)
        }
        
        startPoint = CGPoint(x: 0, y: 0)
        endPoint = CGPoint(x: 1, y: 0)
    }
    
    func getGradientImage() -> UIImage? {
        var image: UIImage?
        
        UIGraphicsBeginImageContext(bounds.size)
        
        if let context = UIGraphicsGetCurrentContext() {
            render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
}
