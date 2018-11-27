//
//  ListViewModel.swift
//  EVO
//
//  Created by Vitalii Vasylyda on 11/26/18.
//  Copyright © 2018 VitaliiVasylyda. All rights reserved.
//

import Foundation

enum ListViewModelStates {
    case reloadData
    case insertNewItems([IndexPath])
    case showEmptyLabel
    case hideEmptyLabel
    case showAlertWith(String)
}

enum PossibleSortTypes: String {
    case popularity = "-popularity"
    case fromTheCheapest = "price"
    case fromTheMostExpensive = "-price"
    case score = "-score"
    case product_opinions = "-product_opinions"
    
    var title: String {
        switch self {
        case .popularity:
            return "Популярность"
            
        case .fromTheCheapest:
            return "От дешевых к дорогим"
            
        case .fromTheMostExpensive:
            return "От дорогих к дешевым"
            
        case .score:
            return "По рейтингу Prom.ua"
            
        case .product_opinions:
            return "По количеству отзывов о товаре"
        }
    }
}

final class ListViewModel {
    
    // MARK: - Properties
    private(set) var listItems: [ListItem] = []
    private(set) var sortTypes: [PossibleSortTypes] = []
    private(set) var isLoading = false
    private(set) var isScrollToTheEnd = false
    private(set) var selectedSortType: PossibleSortTypes = .popularity
    
    var statesCalback: ((ListViewModelStates) -> ())?
    
    // MARK: - Public methods
    
    func startLoadItemsWith(_ offset: Int = 0, limit: Int = 20, sort: PossibleSortTypes = .popularity, isReload: Bool = false) {
        selectedSortType = sort
        
        guard let url = URL(string: "http://prom.ua/_/graph/request?limit=\(limit)&offset=\(offset)&category=35402&sort=\(sort.rawValue)") else {
            statesCalback?(listItems.count > 0 ? .hideEmptyLabel : .showEmptyLabel)
            statesCalback?(.showAlertWith("Oops! Something went wrong"))
            return
        }
        
        isLoading = true
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["content-type": "application/json"]
        
        let queryString = "[{:catalog [:possible_sorts {:results [:id :name :presence_title :price_currency :discounted_price :price :url_main_image_200x200]}]}]"
        
        let data = queryString.data(using: .utf8)
        request.httpBody = data
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
                DispatchQueue.main.async {
                    guard let data = data, let `self` = self else { return }
                    
                    do {
                        if let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> {
                            if let catalog = dict["catalog"] as? Dictionary<String, Any> {
                                if let filters = catalog["possible_sorts"] as? [String] {
                                    self.createSortTypes(filters)
                                }
                                
                                if let result = catalog["results"] as? [Dictionary<String, Any>] {
                                    let data = try? JSONSerialization.data(withJSONObject: result, options: [])
                                    
                                    let decoder = JSONDecoder()
                                    let listItems = try decoder.decode([ListItem].self, from: data!)
                                    
                                    self.listItems.append(contentsOf: listItems)
                                    self.isLoading = false
                                    
                                    if isReload {
                                        self.isScrollToTheEnd = false
                                        self.statesCalback?(.reloadData)
                                        self.statesCalback?(self.listItems.count > 0 ? .hideEmptyLabel : .showEmptyLabel)
                                    } else {
                                        let startIndex = self.listItems.count - listItems.count
                                        let endIndex = self.listItems.count - 1
                                        let indexPaths = Array(startIndex...endIndex).map { IndexPath(item: $0, section: 0) }
                                        
                                        self.isScrollToTheEnd = listItems.count == 0
                                        self.statesCalback?(.insertNewItems(indexPaths))
                                        self.statesCalback?(self.listItems.count > 0 ? .hideEmptyLabel : .showEmptyLabel)
                                    }
                                }
                            }
                        }
                    } catch let error {
                        print("Err", error)
                        self.statesCalback?(.showAlertWith(error.localizedDescription))
                        self.statesCalback?(self.listItems.count > 0 ? .hideEmptyLabel : .showEmptyLabel)
                    }
                }
            }
            
            task.resume()
        }
    }
    
    
    func eraseData() {
        listItems.removeAll()
    }
    
    // MARK: - Private methods
    
    private func createSortTypes(_ sortTypes: [String]) {
        self.sortTypes = sortTypes.compactMap { PossibleSortTypes(rawValue: $0) }
    }
}
