//
//  SavedNodesViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 14.02.2023.
//

import UIKit

//  A controller that displays objects stored in memory (created or modified).
class SavedNodesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: ShowTappedObject?
    
    //  The variable in which the reference to the last pressed button "Bulb" is written, which highlights the tapped object. When you click on another object, the backlight is removed, the link changes.
    private var activeBulb: MultiSelectBotton?
        
    var tableView = UITableView()
    var cellId = "cell"
    var tableData: [SaveNodeCellData] = []
    //  An array in which the IDs of the selected objects are stored.
    var selectedIDs: [Int] = []
    
    override func viewDidLoad() {
        setToolBar()
        fillData()
        setTableView()
    }
    
    func setToolBar() {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let publishButtom = UIBarButtonItem(title: "Publish", style: .plain, target: self, action: #selector(tapSendButton))
        toolbarItems = [flexibleSpace, publishButtom, flexibleSpace]
        navigationController?.setToolbarHidden(false, animated: false)
        let checkAll = UIImageView(image: UIImage(systemName: "checkmark.square"))
        let checkAllTap = UITapGestureRecognizer(target: self, action: #selector(tapCheckAll))
        checkAll.addGestureRecognizer(checkAllTap)
        checkAll.addConstraints([
            checkAll.widthAnchor.constraint(equalToConstant: 25),
            checkAll.heightAnchor.constraint(equalToConstant: 25),
        ])
        let checkAllBar = UIBarButtonItem(customView: checkAll)
        navigationItem.setRightBarButton(checkAllBar, animated: false)
    }
    
    //  The target of the button for selecting all saved objects.
    @objc func tapCheckAll() {
        if selectedIDs.isEmpty {
            for (id, _) in AppSettings.settings.savedObjects {
                selectedIDs.append(id)
            }
        } else {
            selectedIDs = []
        }
        tableView.reloadData()
    }
    
    //  The method of filling in tabular data. It defines the icon of the object, the icon of the object type, the name of the preset and the id of the object.
    func fillData() {
        title = "\(AppSettings.settings.savedObjects.count) objects saved"
        tableData = []
        for (_, object) in AppSettings.settings.savedObjects {
            var properties: [String: String] = [:]
            for tag in object.tag {
                properties[tag.k] = tag.v
            }
            var iconName = ""
            switch object.type {
            case .node:
                iconName = "osm_element_node"
            case .way:
                iconName = "osm_element_way"
            case .closedway:
                iconName = "osm_element_closedway"
            case .multipolygon:
                iconName = "osm_element_area"
            }
            var data = SaveNodeCellData(itemIcon: nil, typeIcon: iconName, itemLabel: nil, idLabel: object.id)
            let pathes = getItemsFromTags(properties: properties)
            if let path = pathes.first {
                if let item = getItemFromPath(path: path) {
                    if let itemIconString = item.icon {
                        let array = itemIconString.components(separatedBy: "/")
                        let icon = array.last
                        data.itemIcon = icon
                        data.itemLabel = item.name
                    }
                }
            }
            tableData.append(data)
        }
//      The data is sorted by id.
        tableData = tableData.sorted(by: { item1, item2 -> Bool in
            item1.idLabel < item2.idLabel
        })
    }
    
    func setTableView() {
        tableView.rowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SavedNodeCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
    }
    
    override func viewDidDisappear(_: Bool) {}

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellFail = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cellFail.textLabel?.text = "Point data loading error"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SavedNodeCell else { return cellFail }
        let data = tableData[indexPath.row]
        if let iconItem = data.itemIcon {
            cell.iconItem.icon.image = UIImage(named: iconItem)
            cell.iconItem.isHidden = false
        } else {
            cell.iconItem.isHidden = true
        }
        cell.iconType.image = UIImage(named: data.typeIcon)
        cell.itemLabel.text = data.itemLabel
        cell.idLabel.text = String(data.idLabel)
        cell.checkBox.indexPath = indexPath
        if selectedIDs.contains(data.idLabel) {
            cell.checkBox.isChecked = true
        } else {
            cell.checkBox.isChecked = false
        }
        cell.checkBox.addTarget(self, action: #selector(tapCheckBox), for: .touchUpInside)
        cell.bulb.key = String(data.idLabel)
        cell.bulb.addTarget(self, action: #selector(tapBulb), for: .touchUpInside)
        return cell
    }
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? SavedNodeCell,
              let idString = cell.idLabel.text,
              let id = Int(idString) else { return }
        guard let object = AppSettings.settings.savedObjects[id] else { return }
        let vector = object.getVectorObject()
//      Highlighting of the tapped object.
        delegate?.showTapObject(object: vector)
        let editVC = EditObjectViewController(object: object)
//      If the user goes to the object tag editing screen, and then deletes the object, a closure is called, which updates the saved data and the table.
        editVC.deleteObjectClosure = { [weak self] _ in
            guard let self = self else { return }
            self.fillData()
            self.tableView.reloadData()
        }
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
            guard let self = self,
                  let cell = self.tableView.cellForRow(at: indexPath) as? SavedNodeCell,
                  let idString = cell.idLabel.text,
                  let id = Int(idString) else { return }
            AppSettings.settings.savedObjects.removeValue(forKey: id)
            self.fillData()
            self.tableView.reloadData()
            self.delegate?.showSavedObjects()
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    //  The method that is called when tapping on the checkbox.
    @objc func tapCheckBox(_ sender: CheckBox) {
        sender.isChecked = !sender.isChecked
        let data = tableData[sender.indexPath.row]
        if sender.isChecked {
            selectedIDs.append(data.idLabel)
        } else {
            guard let i = selectedIDs.firstIndex(of: data.idLabel) else {
                showAction(message: "ID \(data.idLabel) not found", addAlerts: [])
                return
            }
            selectedIDs.remove(at: i)
        }
    }
    
    //  The method that is called when the "Bulb" backlight button is pressed.
    @objc func tapBulb(_ sender: MultiSelectBotton) {
        if activeBulb == sender {
            // Resetting the active button and color when pressed again.
            activeBulb?.backgroundColor = .clear
            activeBulb = nil
        } else {
            // Resetting the color for the currently active button.
            activeBulb?.backgroundColor = .clear

            // Installing a new active button and changing its color.
            sender.backgroundColor = .lightGray
            activeBulb = sender
        }
        guard let key = sender.key,
              let id = Int(key),
              let object = AppSettings.settings.savedObjects[id] else { return }
        let vector = object.getVectorObject()
        delegate?.showTapObject(object: vector)
    }
    
    //  The method of sending data to the server.
    @objc func tapSendButton() {
        if selectedIDs.count == 0 {
            showAction(message: "Select objects!", addAlerts: [])
            return
        }
        let indicator = showIndicator()
        var objects: [OSMAnyObject] = []
        for id in selectedIDs {
            guard let object = AppSettings.settings.savedObjects[id] else { continue }
            objects.append(object)
        }
        let sendObjects = objects
        Task {
            do {
                try await OsmClient.client.sendObjects(sendObjs: sendObjects, deleteObjs: [])
                for id in self.selectedIDs {
                    AppSettings.settings.savedObjects.removeValue(forKey: id)
                }
//              After successfully sending the changes, we update the downloaded data from the server, delete objects from memory.
                delegate?.updateSourceData()
                selectedIDs = []
                fillData()
                tableView.reloadData()
                removeIndicator(indicator: indicator)
                let alert0 = UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    if AppSettings.settings.savedObjects.count == 0 {
                        self.dismiss(animated: true)
                    }
                })
                showAction(message: "Changes have been sent successfully", addAlerts: [alert0])
            } catch {
                let message = error as? String ?? "Data sending error"
                removeIndicator(indicator: indicator)
                showAction(message: message, addAlerts: [])
            }
        }
    }
}
