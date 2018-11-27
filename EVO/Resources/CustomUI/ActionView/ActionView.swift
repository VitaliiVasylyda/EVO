//
//  ActionView.swift
//  EVO
//
//  Created by Vitalii Vasylyda on 11/26/18.
//  Copyright © 2018 VitaliiVasylyda. All rights reserved.
//

import UIKit

final class ActionView: UIView, NibLoadable {
    
    // MARK: - IBOutlet
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    // MARK: - properties
    
    var titleString: String? {
        didSet {
            titleLabel.text = titleString
        }
    }
}
