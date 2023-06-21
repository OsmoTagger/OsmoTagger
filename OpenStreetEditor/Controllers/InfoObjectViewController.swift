//
//  InfoObjectViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 05.04.2023.
//

import UIKit

//  A simple controller for displaying brief information about the object being edited.
class InfoObjectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var object: OSMAnyObject
    
    var dismissClosure: (() -> Void)?
    
    var tableView = UITableView()
    var cellId = "cell"
    var tableData: [InfoCellData] = []
    
    init(object: OSMAnyObject) {
        self.object = object
        super.init(nibName: nil, bundle: nil)
        fillData()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setToolBar()
        setTitleView()
        setTableView()
    }
    
    override func viewDidDisappear(_: Bool) {
        if let clouser = dismissClosure {
            clouser()
        }
    }
    
    func setToolBar() {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel changes", style: .plain, target: self, action: #selector(tapRevert))
        let editButton = UIBarButtonItem(title: "Edit object", style: .plain, target: self, action: #selector(tapEdit))
        let unmarkButton = UIBarButtonItem(title: "Unmark to deletion", style: .plain, target: self, action: #selector(tapUnmark))
        if AppSettings.settings.savedObjects[object.id] != nil {
            toolbarItems = [flexibleSpace, cancelButton, flexibleSpace, editButton, flexibleSpace]
        } else if AppSettings.settings.deletedObjects[object.id] != nil {
            toolbarItems = [flexibleSpace, unmarkButton, flexibleSpace, editButton, flexibleSpace]
        }
    }
    
    @objc func tapRevert() {
        let action0 = UIAlertAction(title: "Cancel changes and edit object", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            AppSettings.settings.savedObjects.removeValue(forKey: self.object.id)
            var tags: [Tag] = []
            for (key, value) in self.object.oldTags {
                let tag = Tag(k: key, v: value, value: "")
                tags.append(tag)
            }
            self.object.tag = tags
            self.navigationController?.popViewController(animated: true)
            let vc = EditObjectViewController(object: self.object)
            self.navigationController?.pushViewController(vc, animated: true)
        })
        let action1 = UIAlertAction(title: "Cancel changes and close object", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            AppSettings.settings.savedObjects.removeValue(forKey: self.object.id)
            self.navigationController?.popViewController(animated: true)
        })
        let action2 = UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in })
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(action0)
        alert.addAction(action1)
        alert.addAction(action2)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func tapEdit() {
        navigationController?.popViewController(animated: true)
        let vc = EditObjectViewController(object: object)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func tapUnmark() {
        AppSettings.settings.deletedObjects.removeValue(forKey: object.id)
        navigationController?.popViewController(animated: true)
    }
    
    func setTitleView() {
        let titleView = SettingsTitleView()
        titleView.icon.image = UIImage(named: "info")
        titleView.label.text = "Info"
        titleView.addConstraints([
            titleView.heightAnchor.constraint(equalToConstant: 30),
        ])
        navigationItem.titleView = titleView
    }
    
    func setTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SimpleCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
    }
    
    func fillData() {
        tableData = []
        if AppSettings.settings.savedObjects[object.id] != nil {
            if object.id < 0 {
                tableData.append(InfoCellData(icon: "plus", text: "Action: creating object"))
            } else {
                tableData.append(InfoCellData(icon: "pencil", text: "Action: editing object tags"))
            }
        } else if AppSettings.settings.deletedObjects[object.id] != nil {
            tableData.append(InfoCellData(icon: "trash", text: "Action: deleting object"))
        }
        var iconTypeName = ""
        switch object.type {
        case .node:
            iconTypeName = "osm_element_node"
        case .way:
            iconTypeName = "osm_element_way"
        case .closedway:
            iconTypeName = "osm_element_closedway"
        case .multipolygon:
            iconTypeName = "osm_element_multipolygon"
        }
        tableData.append(InfoCellData(icon: iconTypeName, text: "Type: \(object.type.rawValue)"))
        
        switch object.type {
        case .node:
            if let lat = object.lat,
               let lon = object.lon
            {
                tableData.append(InfoCellData(icon: "location.circle", text: "Lat: \(lat)\nlon: \(lon)"))
            }
        case .way, .closedway:
            var points = "Points:"
            for (_, node) in object.nodes {
                points += "\nlat: \(node.lat), lon: \(node.lon)"
            }
            tableData.append(InfoCellData(icon: "link", text: points))
        default:
            break
        }
        
        tableData.append(InfoCellData(icon: "number", text: "ID: \(object.id)"))
        var oldTags: [String] = []
        for (key, value) in object.oldTags {
            oldTags.append(key + "=" + value)
        }
        oldTags.sort()
        var oldTagsText = "Old tags:\n"
        if oldTags.count == 0 {
            oldTagsText = "Created point without tags"
        } else {
            for tag in oldTags {
                oldTagsText += "\n" + tag
            }
        }
        tableData.append(InfoCellData(icon: "tag", text: oldTagsText))
        var newProperties: [String: String] = [:]
        for tag in object.tag {
            newProperties[tag.k] = tag.v
        }
        var pathes: [ItemPath] = []
        if newProperties.count == 0 {
            pathes = getItemsFromTags(properties: object.oldTags)
        } else {
            pathes = getItemsFromTags(properties: newProperties)
        }
        if let path = pathes.first {
            if let item = getItemFromPath(path: path) {
                var text = ""
                if let group = path.group {
                    text = "Specific preset: " + group + " - " + path.item
                } else {
                    text = "Specific preset: " + path.category + " - " + path.item
                }
                tableData.insert(InfoCellData(icon: item.icon, text: text), at: 1)
            }
        }
        if NSDictionary(dictionary: object.oldTags).isEqual(to: newProperties) {
            return
        } else {
            var newTags: [String] = []
            for (key, value) in newProperties {
                newTags.append(key + "=" + value)
            }
            newTags.sort()
            var newText = "New tags:\n"
            for tag in newTags {
                newText += "\n" + tag
            }
            tableData.append(InfoCellData(icon: "tag", text: newText))
        }
    }
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SimpleCell else {
            return UITableViewCell()
        }
        let data = tableData[indexPath.row]
        if let icon = data.icon {
            if let image = UIImage(named: icon) {
                cell.icon.icon.image = image
                cell.icon.backView.backgroundColor = .white
            } else {
                let image = UIImage(systemName: icon)
                cell.icon.icon.image = image
                cell.icon.backView.backgroundColor = .systemBackground
            }
            cell.icon.isHidden = false
        } else {
            cell.icon.isHidden = true
        }
        cell.label.text = data.text
        return cell
    }
}
