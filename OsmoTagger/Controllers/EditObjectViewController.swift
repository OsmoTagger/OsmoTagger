//
//  PropViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 26.02.2023.
//

import SafariServices
import UIKit

//  Object tag editing controller.
class EditObjectViewController: UIViewController {
    //  Called when the object is completely deleted from the server. Used only on SavedNodesVC.
    var deleteObjectClosure: ((Int) -> Void)?
    
    var object: OSMAnyObject {
        didSet {
            AppSettings.settings.editableObject = object.vector
        }
    }

    var newProperties: [String: String] = [:] {
        didSet {
            saveObject()
        }
    }
    
    //  A variable necessary for a quick transition to the desired category if the preset of the object is defined. It is not reset to zero, even if you delete the preset tags, all the same, when tapping on the titleView, the transition is made to the last category.
    var titlePath: ItemPath?
    //  A variable that is equal to the path of the defined preset. It is reset to zero if the tags are deleted and the preset is not defined. It is necessary to highlight the active preset when switching to CategoryVC to select a new preset.
    var activePath: ItemPath?
    
    var tableData: [EditSectionData] = []

    var tableView = UITableView()
    var cellId = "cell"

    //  The view that is displayed when manually entering text.
    var addTagView = AddTagManuallyView()
    var addViewBottomConstraint = NSLayoutConstraint()
    
    init(object: OSMAnyObject) {
        self.object = object
        super.init(nibName: nil, bundle: nil)
        fillNewProperties()
        fillData()
        AppSettings.settings.editableObject = object.vector
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
        
//      If the point is newly created and no tags are specified, the preset selection controller is called.
        if object.tag.count == 0 {
            tapTitleButton()
        }
        
        setRightBarItems()
        setTableView()
        setEnterTagManuallyView()
        setToolBar()
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillAppear(_: Bool) {
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
    
    func setRightBarItems() {
        // A button for viewing brief information about the object being edited.
        let infoView = UIImageView(image: UIImage(named: "info"))
        let tapInfo = UITapGestureRecognizer(target: self, action: #selector(tapInfo))
        infoView.addGestureRecognizer(tapInfo)
        infoView.addConstraints([
            infoView.widthAnchor.constraint(equalToConstant: 25),
            infoView.heightAnchor.constraint(equalToConstant: 25),
        ])
        let infoBar = UIBarButtonItem(customView: infoView)
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
        let iconTypeBar = UIBarButtonItem(customView: iconType)
        navigationItem.setRightBarButtonItems([infoBar, iconTypeBar], animated: true)
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
            if NSDictionary(dictionary: object.oldTags).isEqual(to: newProperties) || newProperties.count == 0 {
                AppSettings.settings.savedObjects.removeValue(forKey: object.id)
            } else if NSDictionary(dictionary: object.oldTags).isEqual(to: newProperties) == false && newProperties.count > 0 {
                var newObject = object
                let tags = generateTags(properties: newProperties)
                newObject.tag = tags
                AppSettings.settings.savedObjects[newObject.id] = newObject
            }
        }
        fillData()
        tableView.reloadData()
        setToolBar()
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
//      We define a list of presets that fall under the object tags and use the first one in the array.
        var pathes = getItemsFromTags(properties: newProperties)
        if pathes.count > 0 {
//            If presets are detected.
            let path = pathes.removeFirst()
            activePath = path
            setTitle(path: path)
            if let item = getItemFromPath(path: path) {
                let optionalTags = EditSectionData(name: "\(item.name) tags", items: item.elements)
                tableData.append(optionalTags)
            }
            for path in pathes {
                if let item = getItemFromPath(path: path) {
                    let elem = ItemElements.presetLink(presetName: item.name)
                    if tableData.isEmpty == false {
                        tableData[0].items.append(elem)
                    }
                }
            }
        } else {
//          If no presets are detected.
            activePath = nil
            setTitle(path: nil)
        }
//      Fill in the section of the table with all the tags filled in.
        fillLastSection()
//      We arrange the preset elements in the right order.
        prepareElements()
    }
    
    //  Fill in the section of the table with all the tags filled in.
    func fillLastSection() {
//      Immediately create cells that will be preset selection buttons and manually enter the tag.
        let addTagsFromPresetButton = ItemElements.presetLink(presetName: "Show other presets")
        let addTagManually = ItemElements.presetLink(presetName: "Add tag manually")
        for (index, data) in tableData.enumerated() {
            if data.name == "Filled tags" {
                var filledTags = tableData.remove(at: index)
                filledTags.items = [addTagsFromPresetButton, addTagManually]
                for (tagKey, tagValue) in newProperties {
                    let elem = ItemElements.key(key: tagKey, value: tagValue)
                    filledTags.items.append(elem)
                }
                tableData.append(filledTags)
                return
            }
        }
        var filledTags = EditSectionData(name: "Filled tags", items: [addTagsFromPresetButton, addTagManually])
        var keys = Array(newProperties.keys)
        keys = keys.sorted()
        for key in keys {
            guard let value = newProperties[key] else { continue }
            let elem = ItemElements.key(key: key, value: value)
            filledTags.items.append(elem)
        }
        tableData.append(filledTags)
    }
    
    //  The Josm preset stores many different elements, including links to other presets and "chunks" - sets of elements that are repeatedly used in defaultpresets.xml .
    //  The method extracts links to chunks, and forms a single array of elements, and adds links to other presets at the end.
    func prepareElements() {
        guard tableData.count > 1 else { return }
        var elements = tableData[0].items
        var presets: [ItemElements] = []
        var i = 0
        var isFinished = false
//      The loop is executed until there are no chunk and references to other presets left in the array.
        while !isFinished && i < 20 {
            i += 1
            for (index, element) in elements.enumerated().reversed() {
                switch element {
                case let .reference(ref):
//                  We remove the chunk from the array (reference) and insert its elements instead.
                    elements.remove(at: index)
                    guard let additionalTags = AppSettings.settings.chunks[ref] else { continue }
                    elements.insert(contentsOf: additionalTags, at: index)
                case .presetLink:
//                  We save links to other presets, which we attach to the end.
                    let preset = elements.remove(at: index)
                    presets.append(preset)
                default:
                    continue
                }
            }
//          Check if there are links to other presets or chunks in the array of elements.
            isFinished = elements.allSatisfy { element -> Bool in
                switch element {
                case .presetLink(_), .reference:
                    return false
                default:
                    return true
                }
            }
        }
        
        if presets.count > 0 {
            var names: [String] = []
            let elem: ItemElements = .label(text: "Add tags from other presets:")
            let uniquePresets = Array(Set(presets))
            var sortedPresets: [ItemElements] = []
            for preset in uniquePresets {
                switch preset {
                case let .presetLink(presetName):
                    names.append(presetName)
                default:
                    continue
                }
            }
            names = names.sorted()
            for name in names {
                for preset in uniquePresets {
                    switch preset {
                    case let .presetLink(presetName):
                        if presetName == name {
                            sortedPresets.append(preset)
                        }
                    default:
                        continue
                    }
                }
            }
            sortedPresets.insert(elem, at: 0)
            elements += sortedPresets
            tableData[0].items = elements
        } else {
            tableData[0].items = elements
        }
    }
        
    func setTitle(path: ItemPath?) {
//      If the preset is defined, we display its icon and name in the titleView, if not, then simply specify the type of object.
        guard let path = path,
              let item = getItemFromPath(path: path),
              let iconName = item.icon
        else {
            title = object.type.rawValue
            navigationItem.titleView = nil
            return
        }
        titlePath = path
        let titleView = EditTitleView()
        titleView.icon.image = UIImage(named: iconName)
        titleView.label.text = item.name
        titleView.layer.cornerRadius = 5
        titleView.layer.borderColor = UIColor.lightGray.cgColor
        titleView.layer.borderWidth = 1
        let tapTitle = UITapGestureRecognizer(target: self, action: #selector(tapTitleButton))
        titleView.addGestureRecognizer(tapTitle)
        titleView.addConstraints([
            titleView.heightAnchor.constraint(equalToConstant: 30),
        ])
        navigationItem.titleView = titleView
    }
    
    //  When tapping on the titleView, we open the CategoryNavigationController, to which we add all the stages of selecting the preset.
    @objc func tapTitleButton() {
        let navVC = CategoryNavigationController()
        navVC.objectProperties = newProperties
        navVC.callbackClosure = { [weak self] updatedProperties in
            guard let self = self else { return }
            self.newProperties = updatedProperties
            self.fillData()
            self.tableView.reloadData()
        }
        if let path = titlePath {
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
    
    func setToolBar() {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let deleteButton = UIBarButtonItem(title: "Delete object", style: .plain, target: self, action: #selector(tapDeleteButton))
        deleteButton.tintColor = .systemRed
        let discardButton = UIBarButtonItem(title: "Discard changes", style: .plain, target: self, action: #selector(tapDiscard))
        if AppSettings.settings.savedObjects[object.id] != nil || AppSettings.settings.deletedObjects[object.id] != nil {
            toolbarItems = [flexibleSpace, discardButton, flexibleSpace]
        } else {
            toolbarItems = [flexibleSpace, deleteButton, flexibleSpace]
        }
    }
    
    //  Tap on the button to display brief information about the object (RightBarItems).
    @objc func tapInfo() {
        var newObject = object
        newObject.tag = generateTags(properties: newProperties)
        let vc = InfoObjectViewController(object: newObject)
        navigationController?.setToolbarHidden(true, animated: false)
        vc.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.navigationController?.setToolbarHidden(false, animated: true)
        }
        navigationController?.pushViewController(vc, animated: true)
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
        setToolBar()
        tableView.reloadData()
    }
    
    @objc func tapDiscard() {
        AppSettings.settings.savedObjects.removeValue(forKey: object.id)
        AppSettings.settings.deletedObjects.removeValue(forKey: object.id)
        let tags = generateTags(properties: object.oldTags)
        object.tag = tags
        newProperties = object.oldTags
        fillData()
        tableView.reloadData()
    }
    
    //  By tap the delete button, you can delete tag changes or the entire object from the server (if it is not referenced by other objects).
    @objc func tapDeleteButton() {
        AppSettings.settings.savedObjects.removeValue(forKey: object.id)
        // When deleting an object, if the object selection controller from several objects was opened before, a closure is called, which updates the table to SelectObjectVC.
        if let clouser = deleteObjectClosure {
            clouser(object.id)
        }
        if object.id > 0 {
            AppSettings.settings.deletedObjects[object.id] = object
        }
        dismissViewController()
    }
    
    //  Generating an array of tags [Tag] from a dictionary with tags.
    func generateTags(properties: [String: String]) -> [Tag] {
        var tags: [Tag] = []
        for (key, value) in properties {
            let tag = Tag(k: key, v: value, value: "")
            tags.append(tag)
        }
        return tags
    }
    
    func setTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ItemCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                                     tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                                     tableView.leftAnchor.constraint(equalTo: view.leftAnchor)])
    }
    
    func setEnterTagManuallyView() {
        //  When the tag is entered manually, addView.callbackClosure is triggered, which passes the entered tag=value pair. The table data is updated.
        addTagView.callbackClosure = { [weak self] addedTag in
            guard let self = self else { return }
            self.addTagView.isHidden = true
            self.view.endEditing(true)
            self.navigationController?.setToolbarHidden(false, animated: true)
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
    
    //  Updating the view when the keyboard appears.
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if keyboardSize.height > 0 {
            addViewBottomConstraint.constant = -keyboardSize.height + view.safeAreaInsets.bottom
        }
    }
    
    //  Updating the view when hiding the keyboard.
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
    
    //  Creating a cell. See enum ItemElements, which presets consist of.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? ItemCell else {
            return UITableViewCell()
        }
        let elem = tableData[indexPath.section].items[indexPath.row]
        cell.selectionStyle = .none
        switch elem {
        case let .key(key, value):
            cell.icon.isHidden = false
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLabel.text = value
            cell.valueLabel.isHidden = false
            cell.label.isHidden = true
            cell.label.text = nil
            cell.button.selectClosure = nil
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.button.indexPath = indexPath
            cell.button.isHidden = false
            cell.rightIcon.isHidden = true
            cell.rightIcon.icon.image = nil
            cell.accessoryType = .none
        case let .link(wiki):
            cell.icon.icon.image = UIImage(named: "osm_wiki_logo")
            cell.icon.backView.backgroundColor = .white
            cell.icon.isHidden = false
            cell.keyLabel.text = wiki
            cell.keyLabel.isHidden = true
            cell.valueLabel.isHidden = true
            cell.valueLabel.text = nil
            cell.label.isHidden = false
            cell.label.text = "Open wiki"
            cell.button.isHidden = false
            cell.button.selectClosure = nil
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.button.indexPath = indexPath
            cell.button.isHidden = false
            cell.rightIcon.isHidden = true
            cell.rightIcon.icon.image = nil
            cell.accessoryType = .disclosureIndicator
        case let .text(_, key):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLabel.text = newProperties[key]
            cell.valueLabel.isHidden = false
            cell.label.isHidden = true
            cell.label.text = nil
            cell.button.selectClosure = nil
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.button.isHidden = false
            cell.button.indexPath = indexPath
            cell.rightIcon.icon.image = UIImage(systemName: "keyboard")
            cell.rightIcon.isHidden = false
            cell.accessoryType = .none
        case let .combo(key, values, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLabel.text = newProperties[key]
            cell.valueLabel.isHidden = false
            cell.label.isHidden = true
            cell.label.text = nil
            cell.button.isHidden = false
            cell.button.indexPath = indexPath
            cell.configureButton(values: values, curentValue: newProperties[key])
            cell.button.selectClosure = { [weak self] newValue in
                guard let self = self else { return }
                if newValue == "Custom value" {
                    self.navigationController?.setToolbarHidden(true, animated: true)
                    self.addTagView.keyField.text = key
                    self.addTagView.keyField.isUserInteractionEnabled = false
                    self.addTagView.valueField.text = self.newProperties[key]
                    self.addTagView.isHidden = false
                    self.addTagView.valueField.becomeFirstResponder()
                } else {
                    self.newProperties[key] = newValue
                    cell.valueLabel.text = newValue
                }
                self.tableView.reloadData()
            }
            cell.rightIcon.icon.image = UIImage(systemName: "chevron.down")
            cell.rightIcon.isHidden = false
            cell.accessoryType = .none
        case let .check(key, text, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            let keyValue = text ?? key
            cell.keyLabel.text = keyValue
            cell.keyLabel.isHidden = false
            cell.valueLabel.isHidden = false
            cell.valueLabel.text = newProperties[key]
            cell.label.isHidden = true
            cell.label.text = nil
            cell.button.isHidden = false
            cell.button.selectClosure = nil
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.button.indexPath = indexPath
            if newProperties[key] != nil {
                cell.rightIcon.icon.image = UIImage(systemName: "checkmark.square")
            } else {
                cell.rightIcon.icon.image = UIImage(systemName: "square")
            }
            cell.rightIcon.isHidden = false
            cell.accessoryType = .none
        case let .presetLink(presetName):
            if presetName == "Show other presets" {
                cell.icon.icon.image = UIImage(systemName: "plus")
                cell.icon.backView.backgroundColor = .systemBackground
                cell.icon.isHidden = false
            } else if presetName == "Add tag manually" {
                cell.icon.icon.image = UIImage(systemName: "pencil")
                cell.icon.backView.backgroundColor = .systemBackground
                cell.icon.isHidden = false
            } else {
                if let item = getItemFromName(name: presetName) {
                    if let icon = item.icon {
                        cell.icon.icon.image = UIImage(named: icon)
                        cell.icon.backView.backgroundColor = .white
                        cell.icon.isHidden = false
                    } else {
                        cell.icon.isHidden = true
                    }
                }
            }
            cell.keyLabel.isHidden = true
            cell.keyLabel.text = nil
            cell.valueLabel.isHidden = true
            cell.valueLabel.text = nil
            cell.label.isHidden = false
            cell.label.text = presetName
            cell.button.isHidden = false
            cell.button.selectClosure = nil
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.button.indexPath = indexPath
            cell.rightIcon.isHidden = true
            cell.rightIcon.icon.image = nil
            cell.accessoryType = .disclosureIndicator
        case let .multiselect(key, _, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLabel.isHidden = false
            if var valuesString = newProperties[key] {
                valuesString = valuesString.replacingOccurrences(of: ";", with: ", ")
                cell.valueLabel.text = valuesString
            } else {
                cell.valueLabel.text = nil
            }
            cell.label.isHidden = true
            cell.label.text = nil
            cell.button.isHidden = false
            cell.button.indexPath = indexPath
            cell.button.selectClosure = nil
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.rightIcon.isHidden = true
            cell.rightIcon.icon.image = nil
            cell.accessoryType = .disclosureIndicator
        case let .label(text):
            cell.icon.isHidden = true
            cell.icon.icon.image = nil
            cell.keyLabel.isHidden = true
            cell.keyLabel.text = nil
            cell.valueLabel.isHidden = true
            cell.valueLabel.text = nil
            cell.label.text = text
            cell.label.isHidden = false
            cell.button.isHidden = true
            cell.rightIcon.isHidden = true
            cell.rightIcon.icon.image = nil
            cell.accessoryType = .none
        default:
            cell.icon.isHidden = true
            cell.keyLabel.isHidden = true
            cell.valueLabel.isHidden = true
            cell.label.isHidden = true
            cell.button.isHidden = true
            cell.button.selectClosure = nil
            cell.rightIcon.isHidden = true
            cell.rightIcon.icon.image = nil
            cell.accessoryType = .none
            cell.backgroundColor = .red
        }
        return cell
    }
    
    @objc func tapButton(sender: SelectButton) {
        guard let indexPath = sender.indexPath,
              let cell = tableView.cellForRow(at: indexPath) as? ItemCell else { return }
        let elem = tableData[indexPath.section].items[indexPath.row]
        switch elem {
        case let .link(wiki):
            let str = "https://wiki.openstreetmap.org/wiki/" + wiki
            guard let url = URL(string: str) else {
                showAction(message: "Error generate URL: \(wiki)", addAlerts: [])
                return
            }
            let svc = CustomSafari(url: url)
            present(svc, animated: true, completion: nil)
        case let .presetLink(presetName):
            if presetName == "Show other presets" {
                tapTitleButton()
            } else if presetName == "Add tag manually" {
                navigationController?.setToolbarHidden(true, animated: true)
                addTagView.keyField.text = nil
                addTagView.keyField.isUserInteractionEnabled = true
                addTagView.valueField.text = nil
                addTagView.isHidden = false
                addTagView.keyField.becomeFirstResponder()
            } else {
                guard let item = getItemFromName(name: presetName) else { return }
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
            }
        case let .multiselect(key, values, _):
            let vc = MultiSelectViewController(values: values, key: key, inputValue: newProperties[key])
            vc.callbackClosure = { [weak self] newValue in
                guard let self = self else { return }
                self.navigationController?.setToolbarHidden(false, animated: false)
                if let value = newValue {
                    self.newProperties[key] = value
                } else {
                    self.newProperties.removeValue(forKey: key)
                }
                self.saveObject()
                self.fillData()
                self.tableView.reloadData()
            }
            navigationController?.setToolbarHidden(true, animated: false)
            navigationController?.pushViewController(vc, animated: true)
        case .text:
            guard let key = cell.keyLabel.text else { return }
            navigationController?.setToolbarHidden(true, animated: true)
            addTagView.keyField.text = key
            addTagView.keyField.isUserInteractionEnabled = false
            addTagView.valueField.text = cell.valueLabel.text
            addTagView.isHidden = false
            addTagView.valueField.becomeFirstResponder()
        case .key:
            guard tableData[indexPath.section].name == "Filled tags",
                  let key = cell.keyLabel.text,
                  let value = cell.valueLabel.text else { return }
            navigationController?.setToolbarHidden(true, animated: true)
            addTagView.keyField.text = key
            addTagView.keyField.isUserInteractionEnabled = true
            addTagView.valueField.text = value
            addTagView.isHidden = false
            addTagView.valueField.becomeFirstResponder()
        case let .check(key, _, valueOn):
            let defValue = valueOn ?? "yes"
            if newProperties[key] == nil {
                newProperties[key] = defValue
                cell.rightIcon.icon.image = UIImage(systemName: "checkmark.square")
            } else {
                newProperties.removeValue(forKey: key)
                cell.rightIcon.icon.image = UIImage(systemName: "square")
            }
        default:
            return
        }
        tableView.reloadData()
    }
    
    //  Deleting a previously entered tag.
    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var tagKey: String?
        let data = tableData[indexPath.section].items[indexPath.row]
        switch data {
        case .link(_), .label(_), .presetLink(_), .reference:
            return nil
        case let .key(key, _):
            tagKey = key
        case let .check(key, _, _):
            tagKey = key
        case let .combo(key, _, _):
            tagKey = key
        case let .multiselect(key, _, _):
            tagKey = key
        case let .text(_, key):
            tagKey = key
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
