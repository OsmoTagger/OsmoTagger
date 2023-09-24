//
//  PropViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 26.02.2023.
//

import SafariServices
import UIKit

//  Object tag editing controller.
class EditObjectViewController: SheetViewController {
    
    var object: OSMAnyObject

    var newProperties: [String: String] = [:] {
        didSet {
            saveObject()
        }
    }
    
    //  A variable that is equal to the path of the defined preset. It is reset to zero if the tags are deleted and the preset is not defined. It is necessary to highlight the active preset when switching to CategoryVC to select a new preset.
    var activePath: ItemPath?
    
    var tableData: [EditSectionData] = []

    var tableView = UITableView()
    var cellId = "cell"

    //  The view that is displayed when manually entering text.
    var addTagView = AddTagManuallyView()
    var addViewBottomConstraint = NSLayoutConstraint()
    
    var iconTypeBar = UIBarButtonItem()
    
    init(object: OSMAnyObject) {
        self.object = object
        super.init()
        fillNewProperties()
        fillData()
    }
    
    deinit {
        AppSettings.settings.editableObject = nil
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // If the point is newly created and no tags are specified, the preset selection controller is called.
        if object.tag.count == 0 {
            showAllPresets()
        }
        
        // If we open EditObjectVC when EditObjectVC was previously open, then upon its deinitialization, the edited object will be reset to nil. To achieve this, we perform a delayed check and update it
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if AppSettings.settings.editableObject == nil {
                AppSettings.settings.editableObject = self?.object.vector
            }
        }
        
        setIconType()
        setMenuButton()
        setTableView()
        setEnterTagManuallyView()
    }
    
    override func viewWillAppear(_: Bool) {
        navigationController?.setToolbarHidden(true, animated: true)
        // Notifications about calling and hiding the keyboard.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_: Bool) {
        AppSettings.settings.editableObject = object.vector
    }
    
    override func viewDidDisappear(_: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setMenuButton() {
        let menuButton = UIButton()
        menuButton.setImage(UIImage(systemName: "ellipsis")?.withTintColor(.buttonColor, renderingMode: .alwaysOriginal), for: .normal)
        let optionClosure = { [weak self] (action: UIAction) in
            guard let self = self else { return }
            switch action.title {
            case "Select preset":
                self.showAllPresets()
            case "Add tag manually":
                self.addNewTag()
            case "Discard changes":
                self.tapDiscard()
            case "Delete object":
                self.tapDelete()
            default:
                return
            }
            self.setMenuButton()
        }
        var optionsArray = [UIAction]()
        optionsArray.append(UIAction(title: "Select preset", image: UIImage(systemName: "list.bullet")?.withTintColor(.buttonColor, renderingMode: .alwaysOriginal), handler: optionClosure))
        optionsArray.append(UIAction(title: "Add tag manually", image: UIImage(systemName: "pencil")?.withTintColor(.buttonColor, renderingMode: .alwaysOriginal), handler: optionClosure))
        if !NSDictionary(dictionary: object.oldTags).isEqual(to: newProperties) || AppSettings.settings.deletedObjects[object.id] != nil {
            optionsArray.append(UIAction(title: "Discard changes", image: UIImage(systemName: "arrow.clockwise")?.withTintColor(.buttonColor, renderingMode: .alwaysOriginal), handler: optionClosure))
        }
        if AppSettings.settings.deletedObjects[object.id] == nil {
            optionsArray.append(UIAction(title: "Delete object", image: UIImage(systemName: "trash")?.withTintColor(.buttonColor, renderingMode: .alwaysOriginal), handler: optionClosure))
        }
        let optionsMenu = UIMenu(title: "", image: nil, identifier: nil, options: .singleSelection, children: optionsArray)
        menuButton.menu = optionsMenu
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.changesSelectionAsPrimaryAction = false
        menuButton.addConstraints([
            menuButton.widthAnchor.constraint(equalToConstant: 25),
            menuButton.heightAnchor.constraint(equalToConstant: 25),
        ])
        let menuBar = UIBarButtonItem(customView: menuButton)
        rightButtons = [menuBar, iconTypeBar]
    }
    
    private func setIconType() {
        // The icon of the object type is a point, way, closedway.
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
        let iconType = UIImageView(image: UIImage(named: iconTypeName))
        iconType.addConstraints([
            iconType.widthAnchor.constraint(equalToConstant: 25),
            iconType.heightAnchor.constraint(equalToConstant: 25),
        ])
        iconTypeBar = UIBarButtonItem(customView: iconType)
    }
    
    //  Called every time the object tags are changed (AppSettings.settings.saveObjectClouser)
    func saveObject() {
        // It is not always necessary to save changes in memory. For correct operation, the saveAllowed variable is introduced, which becomes false at the right moment and the changes are not written to memory.
        if object.id < 0 {
            // If the point is newly created, id < 0.
            var newObject = object
            let tags = generateTags(properties: newProperties)
            newObject.tag = tags
            AppSettings.settings.savedObjects[newObject.id] = newObject
        } else {
            // If id > 0, then the previously created object is being edited. If the new tags differ from the original ones, the object is stored in memory, if they are equal, then it is deleted from memory, because there are no changes.
            if NSDictionary(dictionary: object.oldTags).isEqual(to: newProperties) || newProperties.count == 0 || AppSettings.settings.deletedObjects[object.id] != nil {
                AppSettings.settings.savedObjects.removeValue(forKey: object.id)
            } else if !NSDictionary(dictionary: object.oldTags).isEqual(to: newProperties) && newProperties.count > 0 && AppSettings.settings.deletedObjects[object.id] != nil {
                var newObject = object
                let tags = generateTags(properties: newProperties)
                newObject.tag = tags
                AppSettings.settings.savedObjects[newObject.id] = newObject
            }
        }
        fillData()
        tableView.reloadData()
        setMenuButton()
    }
    
    func fillNewProperties() {
        var properties: [String: String] = [:]
        for tag in object.tag {
            properties[tag.k] = tag.v
        }
        newProperties = properties
    }
    
    func fillData() {
        tableData = []
        // We define a list of presets that fall under the object tags and use the first one in the array.
        var pathes = PresetClient().getItemsFromTags(properties: newProperties)
        if pathes.count > 0 {
            // If presets are detected.
            var presetsSet: Set<ItemPath> = []
            for path in pathes {
                presetsSet.insert(path)
                guard let item = PresetClient().getItemFromPath(path: path),
                      let itemPath = item.path else {continue}
                presetsSet.insert(itemPath)
                for element in item.elements {
                    switch element {
                    case let .presetLink(presetName):
                        guard let item = PresetClient().getItemFromName(name: presetName),
                              let itemPath = item.path else {continue}
                        presetsSet.insert(itemPath)
                    default:
                        continue
                    }
                }
            }
            var presets: [ItemPath] = []
            for presetName in presetsSet {
                presets.append(presetName)
            }
            presets = presets.sorted()
            var optionalTags = EditSectionData(name: "Presets", items: [])
            for preset in presets {
                optionalTags.items.append(ItemElements.item(path: preset))
            }
            tableData.append(optionalTags)
            let path = pathes.first!
            activePath = path
            setTitle(path: path)
        } else {
            // If no presets are detected.
            activePath = nil
            setTitle(path: nil)
        }
        // Fill in the section of the table with all the tags filled in.
        fillLastSection()
    }
    
    //  Fill in the section of the table with all the tags filled in.
    func fillLastSection() {
        var filledTags = EditSectionData(name: "Filled tags", items: [])
        var keys = Array(newProperties.keys)
        keys = keys.sorted()
        for key in keys {
            guard let value = newProperties[key] else { continue }
            let elem = ItemElements.key(key: key, value: value)
            filledTags.items.append(elem)
        }
        tableData.append(filledTags)
    }
        
    func setTitle(path: ItemPath?) {
        // If the preset is defined, we display its icon and name in the titleView, if not, then simply specify the type of object.
        guard let path = path,
              let item = PresetClient().getItemFromPath(path: path),
              let iconName = item.icon
        else {
            title = object.type.rawValue
            navigationItem.titleView = nil
            return
        }
        
        let titleView = EditTitleView()
        titleView.icon.image = UIImage(named: iconName)
        titleView.label.text = item.name
        titleView.layer.cornerRadius = 5
        titleView.layer.borderColor = UIColor.lightGray.cgColor
        titleView.layer.borderWidth = 1
        let tapTitle = UITapGestureRecognizer(target: self, action: #selector(showAllPresets))
        titleView.addGestureRecognizer(tapTitle)
        titleView.addConstraints([
            titleView.heightAnchor.constraint(equalToConstant: 30),
        ])
        navigationItem.titleView = titleView
    }
    
    // When tapping on the titleView, we open the CategoryNavigationController, to which we add all the stages of selecting the preset.
    @objc func showAllPresets() {
        let navVC = CategoryNavigationController()
        navVC.objectProperties = newProperties
        navVC.callbackClosure = { [weak self] updatedProperties in
            guard let self = self else { return }
            self.newProperties = updatedProperties
            self.fillData()
            self.tableView.reloadData()
        }
        if let path = activePath {
            let vc0 = CategoryViewController(categoryName: nil, groupName: nil, lastPreset: activePath, elementType: object.type)
            navVC.viewControllers.append(vc0)
            let vc1 = CategoryViewController(categoryName: path.category, groupName: nil, lastPreset: activePath, elementType: object.type)
            navVC.viewControllers.append(vc1)
            if let group = path.group {
                let vc2 = CategoryViewController(categoryName: path.category, groupName: group, lastPreset: activePath, elementType: object.type)
                navVC.viewControllers.append(vc2)
            }
        } else {
            let firstVC = CategoryViewController(categoryName: nil, groupName: nil, lastPreset: activePath, elementType: object.type)
            navVC.viewControllers.append(firstVC)
        }
        present(navVC, animated: true, completion: nil)
    }
    
    func dismissViewController() {
        guard let controllers = navigationController?.viewControllers else {
            dismiss(animated: true)
            return
        }
        if controllers.count > 1 {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    func updateViewController(newObject: OSMAnyObject) {
        object = newObject
        fillNewProperties()
        fillData()
        setMenuButton()
        tableView.reloadData()
        AppSettings.settings.editableObject = newObject.vector
    }
    
    // By tap the delete button, you can delete tag changes or the entire object from the server (if it is not referenced by other objects).
    @objc private func tapDelete() {
        AppSettings.settings.savedObjects.removeValue(forKey: object.id)
        if object.id > 0 {
            AppSettings.settings.deletedObjects[object.id] = object
        }
        dismissViewController()
    }
    
    @objc private func tapDiscard() {
        AppSettings.settings.savedObjects.removeValue(forKey: object.id)
        AppSettings.settings.deletedObjects.removeValue(forKey: object.id)
        let tags = generateTags(properties: self.object.oldTags)
        self.object.tag = tags
        self.newProperties = self.object.oldTags
        self.fillData()
        self.tableView.reloadData()
    }
    
    @objc private func addNewTag() {
        addTagView.keyField.text = nil
        addTagView.keyField.isUserInteractionEnabled = true
        addTagView.valueField.text = nil
        addTagView.isHidden = false
        addTagView.keyField.becomeFirstResponder()
    }
    
    // Generating an array of tags [Tag] from a dictionary with tags.
    func generateTags(properties: [String: String]) -> [Tag] {
        var tags: [Tag] = []
        for (key, value) in properties {
            let tag = Tag(k: key, v: value)
            tags.append(tag)
        }
        return tags
    }
    
    func setTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EditCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                                     tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                                     tableView.leftAnchor.constraint(equalTo: view.leftAnchor)])
    }
    
    func setEnterTagManuallyView() {
        // When the tag is entered manually, addView.callbackClosure is triggered, which passes the entered tag=value pair. The table data is updated.
        addTagView.callbackClosure = { [weak self] addedTag in
            guard let self = self else { return }
            self.addTagView.isHidden = true
            self.view.endEditing(true)
            for (key, value) in addedTag {
                if key == "" || value == "" {
                    let text = """
                    Key or value cannot be empty!
                    Key = "\(key)"
                    Value = "\(value)"
                    """
                    self.showAction(message: text, addAlerts: [])
                    return
                }
            }
            self.newProperties.merge(addedTag, uniquingKeysWith: { _, new in new })
            self.fillData()
            self.tableView.reloadData()
        }
        addViewBottomConstraint = NSLayoutConstraint(item: addTagView, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
        addTagView.isHidden = true
        addTagView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addTagView)
        NSLayoutConstraint.activate([
            addTagView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            addTagView.leftAnchor.constraint(equalTo: view.leftAnchor),
            addTagView.rightAnchor.constraint(equalTo: view.rightAnchor),
            addViewBottomConstraint,
        ])
    }
    
    // Updating the view when the keyboard appears.
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if keyboardSize.height > 0 {
            addViewBottomConstraint.constant = -keyboardSize.height + view.safeAreaInsets.bottom
        }
    }
    
    // Updating the view when hiding the keyboard.
    @objc func keyboardWillHide(notification _: NSNotification) {
        addViewBottomConstraint.constant = 0
    }
}

extension EditObjectViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableData[section].name
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].items.count
    }
    
    // Creating a cell. See enum ItemElements, which presets consist of.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? EditCell else {
            return UITableViewCell()
        }
        let data = tableData[indexPath.section].items[indexPath.row]
        cell.configure(data: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = tableData[indexPath.section].items[indexPath.row]
        switch data {
        case let .key(key, value):
            addTagView.keyField.text = key
            addTagView.keyField.isUserInteractionEnabled = true
            addTagView.valueField.text = value
            addTagView.isHidden = false
            addTagView.valueField.becomeFirstResponder()
        case let .item(path):
            guard let item = PresetClient().getItemFromPath(path: path) else { return }
            let itemVC = ItemTagsViewController(item: item)
            let navVC = CategoryNavigationController(rootViewController: itemVC)
            navVC.objectProperties = newProperties
            navVC.callbackClosure = { [weak self] updatedProperties in
                guard let self = self else { return }
                self.newProperties = updatedProperties
                self.fillData()
                self.tableView.reloadData()
            }
            present(navVC, animated: true, completion: nil)
        default:
            return
        }
    }
    
    // Deleting a previously entered tag.
    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard tableData[indexPath.section].name == "Filled tags" else {return nil}
        var tagKey: String?
        let data = tableData[indexPath.section].items[indexPath.row]
        switch data {
        case let .key(key, _):
            tagKey = key
        default:
            return nil
        }
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
            guard let self = self,
                  let key = tagKey else { return }
            self.newProperties.removeValue(forKey: key)
            let tags = self.generateTags(properties: self.newProperties)
            self.object.tag = tags
            self.fillData()
            self.tableView.reloadData()
            completionHandler(true)
        }
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
}
