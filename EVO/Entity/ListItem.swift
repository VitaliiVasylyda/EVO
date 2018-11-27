//
//  ListItem.swift
//  EVO
//
//  Created by Vitalii Vasylyda on 11/26/18.
//  Copyright © 2018 VitaliiVasylyda. All rights reserved.
//

import Foundation

final class ListItem: Codable {
    var id = 0
    var name = ""
    var presence_title = ""
    var price_currency = ""
    var discounted_price = ""
    var price = ""
    var url_main_image_200x200 = ""
}
