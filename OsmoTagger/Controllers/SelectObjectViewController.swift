//
//  SelectObjectViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 29.03.2023.
//

import UIKit

//  The controller that is called if several objects are detected under the tap to provide a choice.
class SelectObjectViewController: SheetViewController, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: UpdateSourceDataProtocol?
    
    //  Called when the controller is closed, to remove the backlight of the tapped objects.
    var callbackClosure: EmptyBlock?
    
    var objects: [OSMAnyObject]
    
    var tableView = UITableView()
    var cellId = "cell"
    var tableData: [SelectObjectCellData] = []
    
    init(objects: [OSMAnyObject]) {
        self.objects = objects
        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        fillData()
        setTableView()
    }
    
    override func viewWillAppear(_: Bool) {
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewDidDisappear(_: Bool) {
        guard let clouser = callbackClosure else { return }
        clouser()
    }
    
    func fillData() {
        tableData = []
        for object in objects {
            var properties: [String: String] = [:]
            for tag in object.tag {
                properties[tag.k] = tag.v
            }
            var data = SelectObjectCellData(iconItem: nil, type: object.type, itemLabel: nil, idLabel: String(object.id))
            let pathes = PresetClient().getItemsFromTags(properties: properties)
            // Defining the preset of the object.
            if let path = pathes.first {
                if let item = PresetClient().getItemFromPath(path: path) {
                    data.iconItem = item.icon
                    data.itemLabel = item.name
                }
            }
            tableData.append(data)
        }
        // Sorting objects by type.
        tableData = tableData.sorted(by: { item1, item2 -> Bool in
            item1.type < item2.type
        })
        title = "\(objects.count) objects"
    }
    
    func setTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SelectObjectCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
    }
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellFail = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cellFail.textLabel?.text = "Point data loading error"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SelectObjectCell else { return cellFail }
        let data = tableData[indexPath.row]
        if let iconItem = data.iconItem {
            cell.iconItem.icon.image = UIImage(named: iconItem)
            cell.iconItem.isHidden = false
        } else {
            cell.iconItem.isHidden = true
        }
        var iconName = ""
        switch data.type {
        case .node:
            iconName = "osm_element_node"
        case .way:
            iconName = "osm_element_way"
        case .closedway:
            iconName = "osm_element_closedway"
        case .multipolygon:
            iconName = "osm_element_multipolygon"
        }
        cell.iconType.image = UIImage(named: iconName)
        let itemText = data.itemLabel ?? "Unknown"
        cell.itemLabel.text = itemText
        cell.idLabel.text = "id: " + data.idLabel
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    //  Opening the object for editing by tap.
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let idString = tableData[indexPath.row].idLabel
        guard let id = Int(idString) else { return }
        for object in objects where object.id == id {
            let vc = EditObjectViewController(object: object)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
