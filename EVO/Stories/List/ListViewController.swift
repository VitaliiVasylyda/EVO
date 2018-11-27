//
//  ViewController.swift
//  EVO
//
//  Created by Vitalii Vasylyda on 11/26/18.
//  Copyright © 2018 VitaliiVasylyda. All rights reserved.
//

import UIKit

struct ListLayoutVariables {
    var cellWidth: CGFloat = 100 // default size
    let cellHeight: CGFloat = 350 // default size
    let interitemSpacing: CGFloat = 5.0
    let lineSpacing: CGFloat = 10.0
    let edgeInset: CGFloat = 10.0
    let sortViewHeight: CGFloat = 60.0
}

final class ListViewController: UIViewController, Alertable {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var sortTypeLabel: UILabel!
    @IBOutlet private weak var contentViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var sortContentView: UIView!
    @IBOutlet private weak var sortTitleLabel: UILabel!
    @IBOutlet private weak var emptyDataSetLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            configureCollectionView()
        }
    }
    
    // MARK: - Properties
    
    private var layoutVariables = ListLayoutVariables()
    private var viewModel = ListViewModel()
    private var imageProvider = ImageProvider()
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        handleStates()
    }
    
    // MARK: - Actions
    
    @IBAction private func sortAction(_ sender: UITapGestureRecognizer) {
        showActionWithFilters()
    }
}

// MARK: - Private methods

private extension ListViewController {
    func configureCollectionView() {
        collectionView.register(ListItemCollectionCell.nib, forCellWithReuseIdentifier: ListItemCollectionCell.reuseIdentifier)
    }
    
    func configureUI() {
        title = "Платья женские"
        imageProvider.placeholder = #imageLiteral(resourceName: "favouriteSelected")
        layoutVariables.cellWidth = view.bounds.width / 2 - (layoutVariables.interitemSpacing + layoutVariables.edgeInset)
    }
    
    func handleStates() {
        activityIndicator.startAnimating()
        viewModel.startLoadItemsWith()
        
        viewModel.statesCalback = { [weak self] event in
            self?.activityIndicator.stopAnimating()
            
            switch event {
            case .reloadData:
                self?.collectionView.reloadData()
                
            case .insertNewItems(let indexPaths):
                self?.collectionView.performBatchUpdates({
                    self?.collectionView.insertItems(at: indexPaths)
                }, completion: nil)
                
            case .showAlertWith(let errorMessage):
                self?.displayMessage("", msg: errorMessage, handler: nil)
                
            case .showEmptyLabel:
                self?.emptyDataSetLabel.isHidden = false
                
            case .hideEmptyLabel:
                self?.emptyDataSetLabel.isHidden = true
            }
        }
    }
    
    func showActionWithFilters() {
        var actions: [PossibleSortTypes: UIAlertAction] = [:]
        
        viewModel.sortTypes.forEach { item in
            let action = UIAlertAction(title: item.title, style: .default, handler: { [unowned self] (action) in
                self.viewModel.eraseData()
                self.activityIndicator.startAnimating()
                
                self.sortTypeLabel.text = item.title
                self.viewModel.startLoadItemsWith(self.viewModel.listItems.count, sort: item, isReload: true)
            })
            
            actions[item] = action
        }
        
        displaySheet(nil, msg: nil, actions: actions.map { $0.value }, cancelActionHandler: nil)
    }
    
    func showSortHeader(_ isShow: Bool = true) {
        contentViewTopConstraint.constant = isShow ? 0 : -layoutVariables.sortViewHeight
    
        UIView.animate(withDuration: 0.3) {
            self.sortContentView.alpha = isShow ? 1.0 : 0.0
            self.view.layoutIfNeeded()
        }
    }
    
    func showActionViewWith(_ text: String) {
        let actionView = ActionView.loadFromNib()
        actionView.titleString = text
        actionView.alpha = 0.0
        actionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionView)
        
        NSLayoutConstraint.activate([
            actionView.widthAnchor.constraint(equalToConstant: 200),
            actionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])

        UIView.animate(withDuration: 0.3, animations: {
            actionView.alpha = 1.0
        }) { success in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                UIView.animate(withDuration: 0.3, animations: {
                    actionView.alpha = 0.0
                }, completion: { success in
                    actionView.removeFromSuperview()
                })
            })
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ListViewController: UICollectionViewDataSource {
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.listItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ListItemCollectionCell.reuseIdentifier, for: indexPath) as! ListItemCollectionCell
        
        let item = viewModel.listItems[indexPath.item]
        
        cell.configureWith(name: item.name, presence: item.presence_title, price: "\(item.price) \(item.price_currency)", image: nil)
        
        cell.image = imageProvider.loadImage(url: URL(string: item.url_main_image_200x200)!, completion: { [weak cell] image in
            cell?.image = image
        })
        
        cell.userDidTouchWithAction = { [unowned self] action in
            switch action {
            case .buy: self.showActionViewWith("Added to basket")
            case .isFavourite(_): self.showActionViewWith("Added to favourite")
            }
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: layoutVariables.cellWidth, height: layoutVariables.cellHeight)
    }
}

// MARK: - UIScrollViewDelegate

extension ListViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.panGestureRecognizer.translation(in: scrollView.superview).y < 0 else { // if scrolls down
            showSortHeader(true)
            
            return
        }
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        showSortHeader(false)
        
        if !viewModel.isLoading, !viewModel.isScrollToTheEnd, offsetY > contentHeight - scrollView.frame.height - layoutVariables.cellHeight * 10 { // - 10 rows height for preloading
            self.activityIndicator.startAnimating()
            viewModel.startLoadItemsWith(viewModel.listItems.count)
        }
    }
}
