//
//  CategoryViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 19.03.2023.
//

import UIKit

//  The navigation controller for the preset catalog. It is used repeatedly with different names of categories and groups.
class CategoryViewController: UIViewController {
    let searchController = UISearchController(searchResultsController: nil)
    var isSearching = false
    
    var categoryName: String?
    var groupName: String?
    //  Variable for highlighting the active preset.
    var activePreset: ItemPath?
    let elementType: OSMObjectType
    
    var tableView = UITableView()
    var cellId = "cell"
    var tableViewBottomConstraint = NSLayoutConstraint()
    var tableData: [CategoryTableData] = []
    var filteredTableData: [CategoryTableData] = []
    
    init(categoryName: String?, groupName: String?, lastPreset: ItemPath?, elementType: OSMObjectType) {
        self.categoryName = categoryName
        self.groupName = groupName
        activePreset = lastPreset
        self.elementType = elementType
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setSearchController()
        
        // Set title
        if groupName != nil {
            title = groupName
        } else {
            title = categoryName
        }
        
        // Displays an icon of the object type.
        setIconType()
        
        fillData()
        setTableView()
    }
    
    override func viewWillAppear(_: Bool) {
        // Notifications about calling and hiding the keyboard.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //  Displays an icon of the object type.
    func setIconType() {
        let iconType = UIImageView()
        var iconName = ""
        switch elementType {
        case .node:
            iconName = "osm_element_node"
        case .way:
            iconName = "osm_element_way"
        case .closedway:
            iconName = "osm_element_closedway"
        case .multipolygon:
            iconName = "osm_element_multipolygon"
        }
        iconType.image = UIImage(named: iconName)
        let iconTypeForBar = UIBarButtonItem(customView: iconType)
        navigationItem.setRightBarButtonItems([iconTypeForBar], animated: true)
    }
        
    func setSearchController() {
        navigationItem.searchController = searchController
        searchController.delegate = self
        searchController.searchBar.delegate = self
    }
    
    @objc func tapDoneButton() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func setTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.rowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: cellId)
        tableViewBottomConstraint = NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableViewBottomConstraint,
        ])
    }
    
    //  The method determines which tags the preset stores, which are the main ones for the preset.
    func getItemTags(item: Item?) -> [String: String] {
        var tags: [String: String] = [:]
        guard let item = item else { return tags }
        for i in item.elements.indices {
            let elem = item.elements[i]
            switch elem {
            case let .key(key, value):
                tags[key] = value
            case let .combo(key, _, defaultValue):
                if let value = defaultValue {
                    tags[key] = value
                } else {
                    continue
                }
            default:
                continue
            }
        }
        return tags
    }
    
    func fillData() {
        if categoryName == nil && groupName == nil {
//          Open the first controller and load the list of categories
            for category in AppSettings.settings.categories {
                let data = CategoryTableData(type: .category, icon: category.icon, text: category.name)
                tableData.append(data)
            }
        } else if categoryName != nil && groupName == nil {
//          go to the category, display groups and presets
            for category in AppSettings.settings.categories where category.name == categoryName {
                let groups = category.group
                let items = category.item
                for group in groups {
                    let data = CategoryTableData(type: .group, icon: group.icon, text: group.name)
                    tableData.append(data)
                }
                for item in items where item.type.contains(elementType) {
                    var data = CategoryTableData(type: .item(tags: getItemTags(item: item)), icon: item.icon, text: item.name)
                    if let categoryName = categoryName {
                        let path = ItemPath(category: categoryName, group: nil, item: item.name)
                        data.path = path
                    }
                    tableData.append(data)
                }
            }
        } else {
            for category in AppSettings.settings.categories where category.name == categoryName {
                for group in category.group where group.name == groupName {
                    for item in group.item where item.type.contains(elementType) {
                        var data = CategoryTableData(type: .item(tags: getItemTags(item: item)), icon: item.icon, text: item.name)
                        if let categoryName = categoryName {
                            let path = ItemPath(category: categoryName, group: group.name, item: item.name)
                            data.path = path
                        }
                        tableData.append(data)
                    }
                }
            }
        }
    }
    
    //  Updating the view when the keyboard appears.
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if keyboardSize.height > 0 {
            tableViewBottomConstraint.constant = -keyboardSize.height + view.safeAreaInsets.bottom
        }
    }
    
    //  Updating the view when hiding the keyboard.
    @objc func keyboardWillHide(notification _: NSNotification) {
        tableViewBottomConstraint.constant = 0
    }
}

// MARK: UITableViewDelegate

extension CategoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if isSearching {
            return filteredTableData.count
        } else {
            return tableData.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? CategoryCell else {
            let cellFail = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
            cellFail.textLabel?.text = "Point data loading error"
            return cellFail
        }
        let data: CategoryTableData
        if isSearching {
            data = filteredTableData[indexPath.row]
        } else {
            data = tableData[indexPath.row]
        }
        if let icon = data.icon {
            cell.icon.icon.image = UIImage(named: icon)
            cell.icon.isHidden = false
        } else {
            cell.icon.isHidden = true
        }
        if isSearching {
            cell.bigLabel.isHidden = true
            cell.smallLabel.text = data.text
            cell.smallLabel.isHidden = false
            if let path = data.path {
                var pathText = path.category
                if let group = path.group {
                    pathText += " > " + group
                }
                cell.pathLabel.text = pathText
                cell.pathLabel.isHidden = false
            } else {
                cell.pathLabel.text = nil
                cell.pathLabel.isHidden = true
            }
        } else {
            cell.smallLabel.text = nil
            cell.smallLabel.isHidden = true
            cell.pathLabel.text = nil
            cell.pathLabel.isHidden = true
            cell.bigLabel.text = data.text
            cell.bigLabel.isHidden = false
        }
        cell.bigLabel.text = data.text
        cell.type = data.type
        switch data.type {
        case let .item(tags):
            // Highlighting of the active preset.
            if activePreset == data.path {
                cell.accessoryType = .checkmark
            } else if tags.count == 0 {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }
        default:
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    
    //  Depending on what the cell stores - a category, a group, or a preset, a tap on it is processed.
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let navController = navigationController as? CategoryNavigationController else { return }
        let data: CategoryTableData
        if isSearching {
            data = filteredTableData[indexPath.row]
        } else {
            data = tableData[indexPath.row]
        }
        switch data.type {
        case .category:
            let vc = CategoryViewController(categoryName: data.text, groupName: nil, lastPreset: activePreset, elementType: elementType)
            navigationController?.pushViewController(vc, animated: true)
        case .group:
            guard let categoryName = categoryName else { return }
            let vc = CategoryViewController(categoryName: categoryName, groupName: data.text, lastPreset: activePreset, elementType: elementType)
            navigationController?.pushViewController(vc, animated: true)
        case let .item(tags):
            if tags.count > 0 {
                for (key, value) in tags {
                    navController.objectProperties[key] = value
                }
                navigationController?.dismiss(animated: true, completion: nil)
            } else {
                guard let path = data.path,
                      let item = getItemFromPath(path: path)
                else {
                    showAction(message: "Coudn't find item in presets: \(data.path), \(searchController.searchBar.text)", addAlerts: [])
                    return
                }
                let vc = ItemTagsViewController(item: item)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

// MARK: UISearchBarDelegate

extension CategoryViewController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        filteredTableData = []
        let searchText = searchText.lowercased()
        if searchText == "" {
            isSearching = false
        } else {
            isSearching = true
        }
        for category in AppSettings.settings.categories {
            for group in category.group {
                for item in group.item where item.type.contains(elementType) {
                    if item.name.lowercased().contains(searchText) {
                        guard let path = item.path else { continue }
                        let data = CategoryTableData(type: .item(tags: getItemTags(item: item)), icon: item.icon, text: item.name, path: path)
                        filteredTableData.append(data)
                    }
                }
            }
            for item in category.item where item.type.contains(elementType) {
                if item.name.lowercased().contains(searchText) {
                    guard let path = item.path else { continue }
                    let data = CategoryTableData(type: .item(tags: getItemTags(item: item)), icon: item.icon, text: item.name, path: path)
                    filteredTableData.append(data)
                }
            }
        }
        tableView.reloadData()
    }
}

// MARK: UISearchControllerDelegate

extension CategoryViewController: UISearchControllerDelegate {
    func didDismissSearchController(_: UISearchController) {
        isSearching = false
        tableView.reloadData()
        filteredTableData = []
    }
}
