//
//  Reusable.swift
//  EVO
//
//  Created by Vitalii Vasylyda on 11/26/18.
//  Copyright © 2018 VitaliiVasylyda. All rights reserved.
//

import Foundation

protocol Reusable: class {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

typealias NibReusable = Reusable & NibLoadable
