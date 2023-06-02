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
    var tableData: [SaveNodeTableData] = []
    //  An array in which the IDs of the selected objects are stored.
    var selectedIDs: [SavedSelectedIndex] = []
    // View for enter comment to chageset
    var enterCommentView = EnterChangesetComment()
    var enterCommentViewConstrains = [NSLayoutConstraint]()
    
    deinit {
        AppSettings.settings.changeSetComment = nil
        enterCommentView.closeClosure = nil
        enterCommentView.enterClosure = nil
    }
    
    override func viewDidLoad() {
        // Notifications about calling and hiding the keyboard.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        title = "Set of changes"
        
        setToolBar()
        fillData()
        setTableView()
        checkUniqInMemory()
    }
    
    override func viewWillAppear(_: Bool) {
        fillData()
        tableView.reloadData()
    }
    
    override func viewDidDisappear(_: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
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
                iconName = "osm_element_area"
            }
            var data = SaveNodeCellData(type: .saved, itemIcon: nil, typeIcon: iconName, itemLabel: nil, idLabel: object.id)
            let pathes = getItemsFromTags(properties: properties)
            if let path = pathes.first {
                if let item = getItemFromPath(path: path) {
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
                iconName = "osm_element_area"
            }
            var data = SaveNodeCellData(type: .saved, itemIcon: nil, typeIcon: iconName, itemLabel: nil, idLabel: object.id)
            let pathes = getItemsFromTags(properties: properties)
            if let path = pathes.first {
                if let item = getItemFromPath(path: path) {
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
                iconName = "osm_element_area"
            }
            var data = SaveNodeCellData(type: .deleted, itemIcon: nil, typeIcon: iconName, itemLabel: nil, idLabel: object.id)
            let pathes = getItemsFromTags(properties: properties)
            if let path = pathes.first {
                if let item = getItemFromPath(path: path) {
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
    
    func setTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
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
        cell.bulb.key = String(data.idLabel)
        cell.bulb.addTarget(self, action: #selector(tapBulb), for: .touchUpInside)
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
        let vector = object.getVectorObject()
        delegate?.showTapObject(object: vector)
        let vc = InfoObjectViewController(object: object)
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
              let id = Int(key) else { return }
        if let object = AppSettings.settings.savedObjects[id] {
            let vector = object.getVectorObject()
            delegate?.showTapObject(object: vector)
        } else if let object = AppSettings.settings.deletedObjects[id] {
            let vector = object.getVectorObject()
            delegate?.showTapObject(object: vector)
        }
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
        setEnterCommentView()
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
                try await OsmClient.client.sendObjects(sendObjs: capturedSavedObjects, deleteObjs: capturedDeletedObjects)
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
                let alert0 = UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    if AppSettings.settings.savedObjects.count == 0, AppSettings.settings.deletedObjects.count == 0 {
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
    
    // Method displays a comment input field of changeset
    func setEnterCommentView() {
        navigationController?.setToolbarHidden(true, animated: false)
        enterCommentView.closeClosure = { [weak self] in
            guard let self = self else { return }
            self.navigationController?.setToolbarHidden(false, animated: false)
        }
        enterCommentView.enterClosure = { [weak self] in
            guard let self = self else { return }
            self.navigationController?.setToolbarHidden(false, animated: false)
            self.sendObjects()
        }
        enterCommentView.backgroundColor = .backColor0
        enterCommentView.layer.borderColor = UIColor.systemGray.cgColor
        enterCommentView.layer.borderWidth = 2
        let comment = generateComment()
        enterCommentView.field.text = comment
        enterCommentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(enterCommentView)
        NSLayoutConstraint.deactivate(enterCommentViewConstrains)
        enterCommentViewConstrains = [
            enterCommentView.rightAnchor.constraint(equalTo: view.rightAnchor),
            enterCommentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            enterCommentView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ]
        NSLayoutConstraint.activate(enterCommentViewConstrains)
    }
    
    //  Updating the view when the keyboard appears.
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if keyboardSize.height > 0 {
            NSLayoutConstraint.deactivate(enterCommentViewConstrains)
            enterCommentViewConstrains = [
                enterCommentView.rightAnchor.constraint(equalTo: view.rightAnchor),
                enterCommentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboardSize.height),
                enterCommentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            ]
            NSLayoutConstraint.activate(enterCommentViewConstrains)
        }
    }
    
    //  Updating the view when hiding the keyboard.
    @objc func keyboardWillHide(notification _: NSNotification) {
        NSLayoutConstraint.deactivate(enterCommentViewConstrains)
        enterCommentViewConstrains = [
            enterCommentView.rightAnchor.constraint(equalTo: view.rightAnchor),
            enterCommentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            enterCommentView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ]
        NSLayoutConstraint.activate(enterCommentViewConstrains)
    }
}
