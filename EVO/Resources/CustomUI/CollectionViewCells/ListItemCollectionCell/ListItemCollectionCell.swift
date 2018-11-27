//
//  ListItemCollectionCell.swift
//  EVO
//
//  Created by Vitalii Vasylyda on 11/26/18.
//  Copyright © 2018 VitaliiVasylyda. All rights reserved.
//

import UIKit

enum ListCellActionsType {
    case buy
    case isFavourite(Bool)
}

final class ListItemCollectionCell: UICollectionViewCell, Reusable, NibLoadable {

    // MARK: - IBOutlet
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var inStockLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    
    // MARK: - Properties
    
    var userDidTouchWithAction: ((ListCellActionsType) -> ())?
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.roundCorners(corners: .allCorners, radius: 6.0, rect: containerView.bounds)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
        titleLabel.text = nil
        priceLabel.text = nil
        inStockLabel.text = nil
    }
    
    // MARK: - Public methods
    
    func configureWith(name: String?, presence: String?, price: String?, image: UIImage?) {
        titleLabel.text = name
        inStockLabel.text = presence
        priceLabel.text = price
    }
    
    // MARK: - Actions
    
    @IBAction private func addToFavouriteAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        userDidTouchWithAction?(.isFavourite(sender.isSelected))
    }
    
    @IBAction private func buyAction(_ sender: UIButton) {
         userDidTouchWithAction?(.buy)
    }
}
