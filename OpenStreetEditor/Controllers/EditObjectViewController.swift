//
//  PropViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 26.02.2023.
//

import SafariServices
import UIKit

//  Object tag editing controller.
class EditObjectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    //  Called when the object is completely deleted from the server. Used only on SavedNodesVC.
    var deleteObjectClosure: ((Int) -> Void)?
    
    var object: OSMAnyObject
    
    //  A variable necessary for a quick transition to the desired category if the preset of the object is defined. It is not reset to zero, even if you delete the preset tags, all the same, when tapping on the titleView, the transition is made to the last category.
    var titlePath: ItemPath?
    //  A variable that is equal to the path of the defined preset. It is reset to zero if the tags are deleted and the preset is not defined. It is necessary to highlight the active preset when switching to CategoryVC to select a new preset.
    var activePath: ItemPath?
    
    var tableData: [EditSectionData] = []
    
    //  The enum that is needed to change the view when the keyboard is called. The behavior when editing a table cell and a UITextField on a manual tag input view is different.
    enum EditableObject {
        case table
        case addView
    }

    var editObject: EditableObject = .table
    
    //  RightBarItems:
    var infoBar = UIBarButtonItem()
    var iconTypeBar = UIBarButtonItem()
    var cancelBar = UIBarButtonItem()

    var tableView = UITableView()
    var tableConstraints = [NSLayoutConstraint]()
    var cellId = "cell"
    //  Saves the indexPath of the cell where the text is being edited.
    var editingIndexPath: IndexPath?
    //  The view that is displayed when manually entering text.
    var addTagView = AddTagManuallyView()
    var addViewConstrains = [NSLayoutConstraint]()
    
    var tap = UIGestureRecognizer()
    
    init(object: OSMAnyObject) {
        self.object = object
        super.init(nibName: nil, bundle: nil)
        fillNewProperties()
        fillData()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
//      If the point is newly created and no tags are specified, the preset selection controller is called.
        if object.tag.count == 0 {
            tapTitleButton()
        }
        AppSettings.settings.saveAllowed = true
        
        // Notifications about calling and hiding the keyboard.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        tableConstraints = [tableView.topAnchor.constraint(equalTo: view.topAnchor),
                            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                            tableView.leftAnchor.constraint(equalTo: view.leftAnchor)]
        
        setRightBarItems()
        setTableView()
        setToolBar(fromSavedNodesVC: true)
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Closure that is performed every time the object tags are changed - AppSettings.settings.newProperties
        AppSettings.settings.saveObjectClouser = { [weak self] in
            guard let self = self else { return }
            self.saveObject()
        }
    }
    
    override func viewDidDisappear(_: Bool) {
        AppSettings.settings.saveObjectClouser = nil
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //  Actions when clicking "undo" tag changes. Tags are reset to the initial state.
    @objc func tapCancel() {
        let tags = generateTags(properties: object.oldTags)
        AppSettings.settings.savedObjects.removeValue(forKey: object.id)
        object.tag = tags
        AppSettings.settings.newProperties = object.oldTags
        fillData()
        tableView.reloadData()
    }
    
    func setRightBarItems() {
//      A button for viewing brief information about the object being edited.
        let infoView = UIImageView(image: UIImage(named: "info"))
        let tapInfo = UITapGestureRecognizer(target: self, action: #selector(tapInfo))
        infoView.addGestureRecognizer(tapInfo)
        infoView.addConstraints([
            infoView.widthAnchor.constraint(equalToConstant: 25),
            infoView.heightAnchor.constraint(equalToConstant: 25),
        ])
        infoBar = UIBarButtonItem(customView: infoView)
//      The icon of the object type is a point, way, closedway.
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
//      A button to cancel tag changes.
        let cancelImage = UIImageView(image: UIImage(systemName: "arrowshape.turn.up.backward.fill"))
        let cancelTap = UITapGestureRecognizer(target: self, action: #selector(tapCancel))
        cancelImage.addGestureRecognizer(cancelTap)
        cancelImage.addConstraints([
            cancelImage.widthAnchor.constraint(equalToConstant: 25),
            cancelImage.heightAnchor.constraint(equalToConstant: 25),
        ])
        cancelBar = UIBarButtonItem(customView: cancelImage)
        updateRightBarItems()
    }
    
    //  Removes or shows the undo tag changes button.
    func updateRightBarItems() {
        if NSDictionary(dictionary: object.oldTags).isEqual(to: AppSettings.settings.newProperties) {
            navigationItem.setRightBarButtonItems([infoBar, iconTypeBar], animated: false)
        } else {
            navigationItem.setRightBarButtonItems([infoBar, iconTypeBar, cancelBar], animated: false)
        }
    }
    
    //  Called every time the object tags are changed (AppSettings.settings.saveObjectClouser)
    func saveObject() {
        updateRightBarItems()
//      It is not always necessary to save changes in memory. For correct operation, the saveAllowed variable is introduced, which becomes false at the right moment and the changes are not written to memory.
        if AppSettings.settings.saveAllowed {
            if object.id < 0 {
//              If the point is newly created, id < 0.
                var newObject = object
                let tags = generateTags(properties: AppSettings.settings.newProperties)
                newObject.tag = tags
                AppSettings.settings.savedObjects[newObject.id] = newObject
            } else {
//              If id > 0, then the previously created object is being edited. If the new tags differ from the original ones, the object is stored in memory, if they are equal, then it is deleted from memory, because there are no changes.
                if NSDictionary(dictionary: object.oldTags).isEqual(to: AppSettings.settings.newProperties) || AppSettings.settings.newProperties.count == 0 {
                    AppSettings.settings.savedObjects.removeValue(forKey: object.id)
                } else if NSDictionary(dictionary: object.oldTags).isEqual(to: AppSettings.settings.newProperties) == false && AppSettings.settings.newProperties.count > 0 {
                    var newObject = object
                    let tags = generateTags(properties: AppSettings.settings.newProperties)
                    newObject.tag = tags
                    AppSettings.settings.savedObjects[newObject.id] = newObject
                }
            }
            fillData()
            tableView.reloadData()
        }
    }
    
    func fillNewProperties() {
        var newProperties: [String: String] = [:]
        for tag in object.tag {
            newProperties[tag.k] = tag.v
        }
        AppSettings.settings.newProperties = newProperties
    }
    
    func fillData() {
        tableData = []
//      We define a list of presets that fall under the object tags and use the first one in the array.
        var pathes = getItemsFromTags(properties: AppSettings.settings.newProperties)
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
        updateRightBarItems()
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
                for (tagKey, tagValue) in AppSettings.settings.newProperties {
                    let elem = ItemElements.key(key: tagKey, value: tagValue)
                    filledTags.items.append(elem)
                }
                tableData.append(filledTags)
                return
            }
        }
        var filledTags = EditSectionData(name: "Filled tags", items: [addTagsFromPresetButton, addTagManually])
        for (tagKey, tagValue) in AppSettings.settings.newProperties {
            let elem = ItemElements.key(key: tagKey, value: tagValue)
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
            let elem: ItemElements = .label(text: "Add tags from other presets:")
            var uniquePresets = Array(Set(presets))
            uniquePresets.insert(elem, at: 0)
            elements += uniquePresets
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
        navVC.callbackClosure = {
            self.addProperties()
        }
        present(navVC, animated: true, completion: nil)
    }
    
    func setToolBar(fromSavedNodesVC: Bool) {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let deleteButton = UIBarButtonItem(title: "Delete object", style: .plain, target: self, action: #selector(tapDeleteButton))
        let discardButton = UIBarButtonItem(title: "Discard changes", style: .plain, target: self, action: #selector(tapDiscard))
        guard let controllers = navigationController?.viewControllers else {
            toolbarItems = [flexibleSpace, deleteButton, flexibleSpace]
            return
        }
        if fromSavedNodesVC {
            if controllers.count > 1 {
                if controllers[controllers.count - 2] is SavedNodesViewController {
                    toolbarItems = [flexibleSpace, discardButton, flexibleSpace]
                } else {
                    toolbarItems = [flexibleSpace, deleteButton, flexibleSpace]
                }
            } else {
                toolbarItems = [flexibleSpace, deleteButton, flexibleSpace]
            }
        } else {
            toolbarItems = [flexibleSpace, deleteButton, flexibleSpace]
        }
    }
    
    //  Tap on the button to display brief information about the object (RightBarItems).
    @objc func tapInfo() {
        var newObject = object
        newObject.tag = generateTags(properties: AppSettings.settings.newProperties)
        let vc = InfoObjectViewController(object: newObject)
        navigationController?.setToolbarHidden(true, animated: false)
        vc.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.navigationController?.setToolbarHidden(false, animated: true)
            AppSettings.settings.saveAllowed = true
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    //  The method is called from the closure when the CategoryNavigationController is collapsed. The tags entered in it are immediately saved in AppSettings.settings.newProperties, and the method updates the table.
    func addProperties() {
        object.tag = generateTags(properties: AppSettings.settings.newProperties)
        tableData = []
        fillData()
        tableView.reloadData()
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
    
    func updateViewController() {
        AppSettings.settings.saveAllowed = false
        fillNewProperties()
        fillData()
        AppSettings.settings.saveAllowed = true
        setToolBar(fromSavedNodesVC: false)
        tableView.reloadData()
    }
    
    @objc func tapDiscard() {
        AppSettings.settings.savedObjects.removeValue(forKey: object.id)
        AppSettings.settings.deletedObjects.removeValue(forKey: object.id)
        dismissViewController()
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
        NSLayoutConstraint.activate(tableConstraints)
    }
    
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
        switch elem {
        case let .key(key, value):
            cell.icon.isHidden = false
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueField.text = value
            cell.valueField.isHidden = false
            cell.valueField.key = key
            cell.valueLable.isHidden = true
            cell.valueField.delegate = self
            cell.checkBox.isHidden = true
            cell.checkLable.isHidden = true
            cell.selectValueButton.isHidden = true
            cell.label.isHidden = true
            cell.accessoryType = .none
        case let .link(wiki):
            cell.icon.icon.image = UIImage(named: "osm_wiki_logo")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = wiki
            cell.keyLabel.isHidden = true
            cell.valueLable.isHidden = true
            cell.valueField.isHidden = true
            cell.label.isHidden = true
            cell.checkLable.isHidden = false
            cell.checkLable.text = "Open wiki"
            cell.checkBox.isHidden = true
            cell.selectValueButton.isHidden = true
            cell.accessoryType = .none
        case let .text(_, key):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLable.isHidden = true
            cell.valueField.text = AppSettings.settings.newProperties[key]
            cell.valueField.isHidden = false
            cell.valueField.key = key
            cell.valueField.delegate = self
            cell.checkLable.isHidden = true
            cell.checkBox.isHidden = true
            cell.selectValueButton.isHidden = true
            cell.accessoryType = .none
        case let .combo(key, values, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLable.isHidden = true
            cell.valueField.isHidden = true
            cell.checkLable.isHidden = true
            cell.checkBox.isHidden = true
            cell.selectValueButton.isHidden = false
            cell.configureButton(values: values)
            cell.accessoryType = .none
        case let .check(key, text, valueOn):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            if text == nil {
                cell.keyLabel.isHidden = false
                cell.checkLable.isHidden = true
            } else {
                cell.keyLabel.isHidden = true
                cell.checkLable.text = text
                cell.checkLable.isHidden = false
            }
            cell.valueLable.isHidden = true
            cell.valueField.isHidden = true
            cell.checkBox.isHidden = false
            cell.checkBox.indexPath = indexPath
            cell.checkBox.addTarget(self, action: #selector(tapCheckBox), for: .touchUpInside)
            let defValue = valueOn ?? "yes"
            if AppSettings.settings.newProperties[key] == defValue {
                cell.checkBox.isChecked = true
            } else {
                cell.checkBox.isChecked = false
            }
            cell.label.isHidden = true
            cell.selectValueButton.isHidden = true
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
            cell.valueLable.isHidden = true
            cell.valueField.isHidden = true
            cell.checkLable.text = presetName
            cell.checkLable.isHidden = false
            cell.checkBox.isHidden = true
            cell.label.isHidden = true
            cell.selectValueButton.isHidden = true
            cell.accessoryType = .disclosureIndicator
        case let .multiselect(key, _, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLable.isHidden = false
            if var valuesString = AppSettings.settings.newProperties[key] {
                valuesString = valuesString.replacingOccurrences(of: ";", with: ", ")
                cell.valueLable.text = valuesString
            } else {
                cell.valueLable.text = nil
            }
            cell.valueField.isHidden = true
            cell.checkLable.isHidden = true
            cell.checkBox.isHidden = true
            cell.selectValueButton.isHidden = true
            cell.accessoryType = .disclosureIndicator
        case let .label(text):
            cell.icon.isHidden = true
            cell.keyLabel.isHidden = true
            cell.valueLable.isHidden = true
            cell.valueField.isHidden = true
            cell.checkLable.isHidden = true
            cell.checkBox.isHidden = true
            cell.label.text = text
            cell.label.isHidden = false
            cell.selectValueButton.isHidden = true
            cell.accessoryType = .none
        default:
            cell.icon.isHidden = true
            cell.keyLabel.isHidden = true
            cell.valueLable.isHidden = true
            cell.valueField.isHidden = true
            cell.checkLable.isHidden = true
            cell.checkBox.isHidden = true
            cell.label.isHidden = true
            cell.selectValueButton.isHidden = true
            cell.accessoryType = .none
            cell.backgroundColor = .red
        }
        return cell
    }
    
//    Tap on the cell is used only for 4 actions:
//    1) Opening links to wiki.openstreetmap.org
//    2) Adding a preset
//    3) Entering the tag manually.
//    4) Switching to the suggested preset.
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let elem = tableData[indexPath.section].items[indexPath.row]
        switch elem {
        case let .link(wiki):
            let str = "https://wiki.openstreetmap.org/wiki/" + wiki
            guard let url = URL(string: str) else { return }
            let svc = CustomSafari(url: url)
            AppSettings.settings.saveAllowed = false
            svc.callbackClosure = { [weak self] in
                AppSettings.settings.saveAllowed = true
            }
            present(svc, animated: true, completion: nil)
        case let .presetLink(presetName):
            if presetName == "Show other presets" {
                tapTitleButton()
            } else if presetName == "Add tag manually" {
                editObject = .addView
                //  When the tag is entered manually, addView.callbackClosure is triggered, which passes the entered tag=value pair. The table data is updated.
                addTagView.callbackClosure = { [weak self] addedTag in
                    guard let self = self else { return }
                    self.navigationController?.setToolbarHidden(false, animated: false)
                    self.editObject = .table
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
                    AppSettings.settings.newProperties.merge(addedTag, uniquingKeysWith: { _, new in new })
                    self.fillData()
                    self.tableView.reloadData()
                }
                addTagView.translatesAutoresizingMaskIntoConstraints = false
                addTagView.backgroundColor = .systemBackground
                addTagView.alpha = 0.95
                addTagView.keyField.becomeFirstResponder()
                view.addSubview(addTagView)
            } else {
                guard let item = getItemFromName(name: presetName) else { return }
                let itemVC = ItemTagsViewController(item: item)
                let navVC = CategoryNavigationController(rootViewController: itemVC)
                navVC.callbackClosure = {
                    self.addProperties()
                }
                present(navVC, animated: true, completion: nil)
            }
        case let .multiselect(key, values, _):
            let vc = MultiSelectViewController(values: values, key: key)
            vc.callbackClosure = { [weak self] in
                guard let self = self else { return }
                self.navigationController?.setToolbarHidden(false, animated: false)
                self.saveObject()
                self.fillData()
                self.tableView.reloadData()
            }
            navigationController?.setToolbarHidden(true, animated: false)
            navigationController?.pushViewController(vc, animated: true)
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    //  Deleting a previously entered tag.
    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard tableData[indexPath.section].name == "Filled tags" else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            guard let cell = self.tableView.cellForRow(at: indexPath) as? ItemCell else { return }
            guard let key = cell.keyLabel.text else { return }
            AppSettings.settings.newProperties.removeValue(forKey: key)
            let tags = self.generateTags(properties: AppSettings.settings.newProperties)
            self.object.tag = tags
            self.fillData()
            self.tableView.reloadData()
            completionHandler(true)
        }
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    //  Tap on the checkbox.
    @objc func tapCheckBox(_ sender: CheckBox) {
        sender.isChecked = !sender.isChecked
        let data = tableData[sender.indexPath.section].items[sender.indexPath.row]
        switch data {
        case let .check(key, _, valueOn):
            let defValue = valueOn ?? "yes"
            if sender.isChecked {
                AppSettings.settings.newProperties[key] = defValue
            } else {
                AppSettings.settings.newProperties.removeValue(forKey: key)
            }
        default:
            return
        }
    }
    
    //  Several methods that are triggered when you finish typing. The finishEdit method is called, which assigns the entered value to the tag.
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        editingIndexPath = nil
        finishEdit(textField)
        view.removeGestureRecognizer(tap)
    }
    
    func finishEdit(_ textField: UITextField) {
        if let textField = textField as? ValueField {
            guard let key = textField.key else {
                showAction(message: "Error get key", addAlerts: [])
                return
            }
            if textField.text == "" {
                AppSettings.settings.newProperties.removeValue(forKey: key)
            } else {
                AppSettings.settings.newProperties[key] = textField.text
            }
        }
        tableView.reloadData()
    }
    
    //  Updating the view when the keyboard appears.
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if keyboardSize.height > 0 {
            switch editObject {
            case .table:
                NSLayoutConstraint.deactivate(tableConstraints)
                tableConstraints = [tableView.topAnchor.constraint(equalTo: view.topAnchor),
                                    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboardSize.height),
                                    tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                                    tableView.leftAnchor.constraint(equalTo: view.leftAnchor)]
                NSLayoutConstraint.activate(tableConstraints)
            case .addView:
                addViewConstrains = [
                    addTagView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboardSize.height),
                    addTagView.leftAnchor.constraint(equalTo: view.leftAnchor),
                    addTagView.rightAnchor.constraint(equalTo: view.rightAnchor),
                    addTagView.topAnchor.constraint(equalTo: view.topAnchor),
                ]
                NSLayoutConstraint.activate(addViewConstrains)
            }
        }
    }
    
    //  Updating the view when hiding the keyboard.
    @objc func keyboardWillHide(notification _: NSNotification) {
        switch editObject {
        case .table:
            NSLayoutConstraint.deactivate(tableConstraints)
            tableConstraints = [tableView.topAnchor.constraint(equalTo: view.topAnchor),
                                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                                tableView.leftAnchor.constraint(equalTo: view.leftAnchor)]
            NSLayoutConstraint.activate(tableConstraints)
        case .addView:
            NSLayoutConstraint.deactivate(addViewConstrains)
            navigationController?.setToolbarHidden(true, animated: false)
            addViewConstrains = [
                addTagView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                addTagView.leftAnchor.constraint(equalTo: view.leftAnchor),
                addTagView.rightAnchor.constraint(equalTo: view.rightAnchor),
                addTagView.topAnchor.constraint(equalTo: view.topAnchor),
            ]
            NSLayoutConstraint.activate(addViewConstrains)
        }
    }
    
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool { return true }
}
