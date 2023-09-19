//
//  SavedNodesViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 14.02.2023.
//

import UIKit

//  A controller that displays objects stored in memory (created or modified).
class SavedNodesViewController: SheetViewController, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: UpdateSourceDataProtocol?
    
    var tableView = UITableView()
    var cellId = "cell"
    var tableData: [SaveNodeTableData] = []
    
    var enterCommentView = ChangesetCommentView()
    
    //  An array in which the IDs of the selected objects are stored.
    var selectedIDs: [SavedSelectedIndex] = [] {
        didSet {
            enterCommentView.field.placeholder = selectedIDs.count == 0 ? nil : generateComment()
        }
    }
    
    var tap = UIGestureRecognizer()
    
    var flexibleSpace = UIBarButtonItem()
    var nilButton = UIBarButtonItem()
    var publishButtom = UIBarButtonItem()
    
    deinit {
        AppSettings.settings.changeSetComment = nil
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        title = "Changeset"
        
        flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        nilButton = UIBarButtonItem(title: "Select objects", style: .plain, target: nil, action: nil)
        publishButtom = UIBarButtonItem(title: "Publish", style: .done, target: self, action: #selector(tapSendButton))
        
        fillData()
        createToolBar()
        setTableView()
        checkUniqInMemory()
        tapCheckAll()
    }
    
    override func viewWillAppear(_: Bool) {
        fillData()
        tableView.reloadData()
    }
    
    func createToolBar() {
        navigationController?.setToolbarHidden(false, animated: false)
        let checkAll = UIImageView(image: UIImage(systemName: "checkmark.square"))
        let checkAllTap = UITapGestureRecognizer(target: self, action: #selector(tapCheckAll))
        checkAll.addGestureRecognizer(checkAllTap)
        checkAll.addConstraints([
            checkAll.widthAnchor.constraint(equalToConstant: 25),
            checkAll.heightAnchor.constraint(equalToConstant: 25),
        ])
        let checkAllBar = UIBarButtonItem(customView: checkAll)
        rightButtons = [checkAllBar]
        setToolBar()
    }
        
    func setToolBar() {
        if selectedIDs.count == 0 {
            toolbarItems = [flexibleSpace, nilButton, flexibleSpace]
        } else {
            toolbarItems = [flexibleSpace, publishButtom, flexibleSpace]
        }
    }
    
    //  The target of the button for selecting all saved objects.
    @objc func tapCheckAll() {
        if selectedIDs.isEmpty {
            for (id, _) in AppSettings.settings.savedObjects {
                let path = SavedSelectedIndex(type: .saved, id: id)
                selectedIDs.append(path)
            }
            for (id, _) in AppSettings.settings.deletedObjects {
                let path = SavedSelectedIndex(type: .deleted, id: id)
                selectedIDs.append(path)
            }
        } else {
            selectedIDs = []
        }
        tableView.reloadData()
        setToolBar()
    }
    
    //  The method of filling in tabular data. It defines the icon of the object, the icon of the object type, the name of the preset and the id of the object.
    func fillData() {
        tableData = []
        // Get saved objects
        var savedNodesItems: [SaveNodeCellData] = []
        for (_, object) in AppSettings.settings.savedObjects {
            guard object.id > 0 else { continue }
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
                iconName = "osm_element_multipolygon"
            }
            var data = SaveNodeCellData(type: .saved, itemIcon: nil, typeIcon: iconName, itemLabel: nil, idLabel: object.id)
            let pathes = PresetClient().getItemsFromTags(properties: properties)
            if let path = pathes.first {
                if let item = PresetClient().getItemFromPath(path: path) {
                    data.itemIcon = item.icon
                    data.itemLabel = item.name
                }
            }
            savedNodesItems.append(data)
        }
        savedNodesItems = savedNodesItems.sorted(by: { item1, item2 -> Bool in
            item1.idLabel < item2.idLabel
        })
        let savedNodes = SaveNodeTableData(name: "Edited objects", items: savedNodesItems)
        if savedNodes.items.count > 0 {
            tableData.append(savedNodes)
        }
        
        var createdNodesItems: [SaveNodeCellData] = []
        for (_, object) in AppSettings.settings.savedObjects {
            guard object.id < 0 else { continue }
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
                iconName = "osm_element_multipolygon"
            }
            var data = SaveNodeCellData(type: .saved, itemIcon: nil, typeIcon: iconName, itemLabel: nil, idLabel: object.id)
            let pathes = PresetClient().getItemsFromTags(properties: properties)
            if let path = pathes.first {
                if let item = PresetClient().getItemFromPath(path: path) {
                    data.itemIcon = item.icon
                    data.itemLabel = item.name
                }
            }
            createdNodesItems.append(data)
        }
        createdNodesItems = createdNodesItems.sorted(by: { item1, item2 -> Bool in
            item1.idLabel < item2.idLabel
        })
        let createdNodes = SaveNodeTableData(name: "Created objects", items: createdNodesItems)
        if createdNodes.items.count > 0 {
            tableData.append(createdNodes)
        }
        
        var deletedObjectItems: [SaveNodeCellData] = []
        for (_, object) in AppSettings.settings.deletedObjects {
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
                iconName = "osm_element_multipolygon"
            }
            var data = SaveNodeCellData(type: .deleted, itemIcon: nil, typeIcon: iconName, itemLabel: nil, idLabel: object.id)
            let pathes = PresetClient().getItemsFromTags(properties: properties)
            if let path = pathes.first {
                if let item = PresetClient().getItemFromPath(path: path) {
                    data.itemIcon = item.icon
                    data.itemLabel = item.name
                }
            }
            deletedObjectItems.append(data)
        }
        deletedObjectItems = deletedObjectItems.sorted(by: { item1, item2 -> Bool in
            item1.idLabel < item2.idLabel
        })
        let deletedNodes = SaveNodeTableData(name: "Deleted objects", items: deletedObjectItems)
        if deletedNodes.items.count > 0 {
            tableData.append(deletedNodes)
        }
    }
    
    func checkUniqInMemory() {
        var editedObjects: [OSMAnyObject] = []
        for (_, object) in AppSettings.settings.savedObjects {
            editedObjects.append(object)
        }
        var deletedObjects: [OSMAnyObject] = []
        for (_, object) in AppSettings.settings.deletedObjects {
            deletedObjects.append(object)
        }
        let result = checkUniq(array1: editedObjects, array2: deletedObjects)
        if result.count > 0 {
            showAction(message: "Attention! The listed objects are modified for submission and are marked for deletion at the same time: \(result)", addAlerts: [])
        }
    }
    
    func checkUniq(array1: [OSMAnyObject], array2: [OSMAnyObject]) -> [Int] {
        var result: [Int] = []
        var arrayID1: [Int] = []
        for object in array1 {
            arrayID1.append(object.id)
        }
        var arrayID2: [Int] = []
        for object in array2 {
            arrayID2.append(object.id)
        }
        for id in arrayID1 {
            if arrayID2.contains(id) {
                result.append(id)
            }
        }
        return result
    }
    
    func numberOfSections(in _: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        let counts = tableData[section].items.count
        if counts > 0 {
            return tableData[section].name
        } else {
            return nil
        }
    }
    
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellFail = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cellFail.textLabel?.text = "Point data loading error"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SavedNodeCell else { return cellFail }
        let data = tableData[indexPath.section].items[indexPath.row]
        if let iconItem = data.itemIcon {
            cell.iconItem.icon.image = UIImage(named: iconItem)
            cell.iconItem.isHidden = false
        } else {
            cell.iconItem.isHidden = true
        }
        cell.iconType.icon.image = UIImage(named: data.typeIcon)
        let itemText = data.itemLabel ?? "Unknown"
        cell.itemLabel.text = itemText
        cell.idLabel.text = "id: " + String(data.idLabel)
        cell.checkBox.indexPath = indexPath
        let selectObject = SavedSelectedIndex(type: data.type, id: data.idLabel)
        if selectedIDs.contains(where: { $0.type == selectObject.type && $0.id == selectObject.id }) {
            cell.checkBox.isChecked = true
        } else {
            cell.checkBox.isChecked = false
        }
        cell.checkBox.addTarget(self, action: #selector(tapCheckBox), for: .touchUpInside)
        return cell
    }
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = tableData[indexPath.section].items[indexPath.row]
        var nilObject: OSMAnyObject?
        switch data.type {
        case .saved:
            nilObject = AppSettings.settings.savedObjects[data.idLabel]
        case .deleted:
            nilObject = AppSettings.settings.deletedObjects[data.idLabel]
        }
        guard let object = nilObject else { return }
        let vc = EditObjectViewController(object: object)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            let data = self.tableData[indexPath.section].items[indexPath.row]
            switch data.type {
            case .saved:
                AppSettings.settings.savedObjects.removeValue(forKey: data.idLabel)
            case .deleted:
                AppSettings.settings.deletedObjects.removeValue(forKey: data.idLabel)
            }
            let path = SavedSelectedIndex(type: data.type, id: data.idLabel)
            if let i = self.selectedIDs.firstIndex(of: path) {
                self.selectedIDs.remove(at: i)
            }
            self.fillData()
            self.tableView.reloadData()
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
        let data = tableData[sender.indexPath.section].items[sender.indexPath.row]
        let newIndex = SavedSelectedIndex(type: data.type, id: data.idLabel)
        if sender.isChecked {
            selectedIDs.append(newIndex)
        } else {
            guard let i = selectedIDs.firstIndex(of: newIndex) else {
                showAction(message: "ID \(data.idLabel) not found", addAlerts: [])
                return
            }
            selectedIDs.remove(at: i)
        }
        setToolBar()
    }
    
    //  The method of sending data to the server.
    @objc func tapSendButton() {
        guard selectedIDs.count > 0 else {
            showAction(message: "Select objects!", addAlerts: [])
            return
        }
        var savedObjects: [OSMAnyObject] = []
        var deletedObjects: [OSMAnyObject] = []
        for path in selectedIDs {
            switch path.type {
            case .saved:
                guard let object = AppSettings.settings.savedObjects[path.id] else { continue }
                savedObjects.append(object)
            case .deleted:
                guard let object = AppSettings.settings.deletedObjects[path.id] else { continue }
                deletedObjects.append(object)
            }
        }
        let uniq = checkUniq(array1: savedObjects, array2: deletedObjects)
        if uniq.count > 0 {
            showAction(message: "Attention! The listed objects are modified for submission and are marked for deletion at the same time: \(uniq). Fix it.", addAlerts: [])
            return
        }
        if enterCommentView.field.text == "" {
            AppSettings.settings.changeSetComment = enterCommentView.field.placeholder
        } else {
            AppSettings.settings.changeSetComment = enterCommentView.field.text
        }
        sendObjects()
    }
    
    func sendObjects() {
        let indicator = showIndicator()
        var savedObjects: [OSMAnyObject] = []
        var deletedObjects: [OSMAnyObject] = []
        for path in selectedIDs {
            switch path.type {
            case .saved:
                guard let object = AppSettings.settings.savedObjects[path.id] else { continue }
                savedObjects.append(object)
            case .deleted:
                guard let object = AppSettings.settings.deletedObjects[path.id] else { continue }
                deletedObjects.append(object)
            }
        }
        let capturedSavedObjects = savedObjects
        let capturedDeletedObjects = deletedObjects
        Task {
            do {
                try await OsmClient().sendObjects(sendObjs: capturedSavedObjects, deleteObjs: capturedDeletedObjects)
                for object in capturedSavedObjects {
                    AppSettings.settings.savedObjects.removeValue(forKey: object.id)
                }
                for object in capturedDeletedObjects {
                    AppSettings.settings.deletedObjects.removeValue(forKey: object.id)
                }
                // After successfully sending the changes, we update the downloaded data from the server, delete objects from memory.
                delegate?.updateSourceData()
                selectedIDs = []
                fillData()
                tableView.reloadData()
                removeIndicator(indicator: indicator)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.enterCommentView.field.text = nil
                    AppSettings.settings.changeSetComment = nil
                }
                Alert.showAlert("Changes have been sent successfully", isBad: false)
                if AppSettings.settings.savedObjects.count == 0 && AppSettings.settings.deletedObjects.count == 0 {
                    self.dismiss(animated: true)
                }
            } catch {
                let message = error as? String ?? "Data sending error"
                Log("Error send objects: \(message)")
                removeIndicator(indicator: indicator)
                showAction(message: message, addAlerts: [])
            }
        }
    }
    
    // The method automatically generates a comment for changeset.
    func generateComment() -> String {
        var comment = ""
        var createdObjects: [OSMAnyObject] = []
        var editedObjects: [OSMAnyObject] = []
        var deletedObjects: [OSMAnyObject] = []
        for path in selectedIDs {
            switch path.type {
            case .saved:
                guard let object = AppSettings.settings.savedObjects[path.id] else { continue }
                if path.id < 0 {
                    createdObjects.append(object)
                } else {
                    editedObjects.append(object)
                }
            case .deleted:
                guard let object = AppSettings.settings.deletedObjects[path.id] else { continue }
                deletedObjects.append(object)
            }
        }
        if editedObjects.count > 0 {
            comment += "\(editedObjects.count) object(s) edited. "
        }
        if createdObjects.count > 0 {
            comment += "\(createdObjects.count) object(s) created. "
        }
        if deletedObjects.count > 0 {
            comment += "\(deletedObjects.count) object(s) deleted."
        }
        return comment
    }

    func setTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        enterCommentView.field.delegate = self
        tableView.tableHeaderView = enterCommentView
        tableView.register(SavedNodeCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
}
    
extension SavedNodesViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textFieldDidBeginEditing(_: UITextField) {
        tap = UITapGestureRecognizer(target: self, action: #selector(endEdit))
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    @objc func endEdit(sender _: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    func textFieldDidEndEditing(_: UITextField) {
        view.removeGestureRecognizer(tap)
    }
}

extension SavedNodesViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool { return true }
}
