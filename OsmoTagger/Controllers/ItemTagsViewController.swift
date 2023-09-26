//
//  ItemTagsViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 19.03.2023.
//

import Foundation
import SafariServices
import UIKit

//  If the main preset tags are not found, the preset tags are opened for manual addition.
class ItemTagsViewController: SheetViewController {
    var item: Item
    
    var tableView = UITableView()
    var cellId = "cell"
    
    var iconTypes: [UIBarButtonItem] = []
    var doneButtonForBar = UIBarButtonItem()
    
    var addTagCallback: TagBlock?
    
    init(item: Item) {
        self.item = item
        super.init()
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = item.name
        prepareElements()
        
        addTagCallback = { [weak self] addedTag in
            guard let self = self else { return }
            self.navigationController?.setToolbarHidden(false, animated: true)
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
            if let navController = self.navigationController as? CategoryNavigationController {
                navController.objectProperties.merge(addedTag, uniquingKeysWith: { _, new in new })
            }
            self.tableView.reloadData()
        }
        
//      Set RightBarItems
        doneButtonForBar = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDoneButton))
        iconTypes = [doneButtonForBar]
        addIconTypes()
        rightButtons = iconTypes
        
        setTableView()
    }
        
    //  The preset stores "chunks" - duplicate sets of tags as elements. In defaultpresets.xml they are taken out separately from Josm. The method extracts tags from the "chunk" and adds preset elements to the array.
    //  The method also transfers references to other presets to the end of the array.
    func prepareElements() {
        var elements = item.elements
        var presets: [ItemElements] = [.label(text: "Add tags from other items:")]
        var i = 0
        var isFinished = false
        while !isFinished && i < 20 {
            i += 1
            for (index, element) in elements.enumerated().reversed() {
                switch element {
                case let .reference(ref):
                    elements.remove(at: index)
                    guard let additionalTags = AppSettings.settings.chunks[ref] else { continue }
                    elements.insert(contentsOf: additionalTags, at: index)
                case .presetLink:
                    let preset = elements.remove(at: index)
                    presets.append(preset)
                default:
                    continue
                }
            }
            isFinished = elements.allSatisfy { element -> Bool in
                switch element {
                case .presetLink(_), .reference:
                    return false
                default:
                    return true
                }
            }
        }
        if presets.count > 1 {
            elements += presets
            item.elements = elements
        } else {
            item.elements = elements
        }
    }
    
    //  Ste icon types of preset
    func addIconTypes() {
        for type in item.type {
            let iconType = UIImageView()
            var iconName = ""
            switch type {
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
            iconTypes.insert(iconTypeForBar, at: 1)
        }
    }
    
    @objc func tapDoneButton() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func setTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ItemCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
                                     tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                                     tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)])
    }
    
    @objc func tapCheckBox(sender: CheckBox) {
        guard let navController = navigationController as? CategoryNavigationController,
              let cell = tableView.cellForRow(at: sender.indexPath) as? ItemCell else { return }
        sender.isChecked = !sender.isChecked
        let elem = item.elements[sender.indexPath.row]
        switch elem {
        case let .key(key, value):
            if sender.isChecked {
                navController.objectProperties[key] = value
                cell.valueLabel.text = value
            } else {
                navController.objectProperties.removeValue(forKey: key)
                cell.valueLabel.text = nil
            }
        case let .check(key, _, valueOn):
            let def = valueOn ?? "yes"
            if sender.isChecked {
                navController.objectProperties[key] = def
                cell.valueLabel.text = def
            } else {
                navController.objectProperties.removeValue(forKey: key)
                cell.valueLabel.text = nil
            }
        default:
            showAction(message: "Bad index of element", addAlerts: [])
        }
        tableView.reloadData()
    }
    
    @objc private func addNewTag(key _: String?, value _: String?) {
        guard let callback = addTagCallback else { return }
        AddTagManuallyView.showAddTagView(key: nil, value: nil, callback: callback)
    }
}

extension ItemTagsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return item.elements.count
    }
    
    @objc func tapButton(sender: SelectButton) {
        guard let navController = navigationController as? CategoryNavigationController,
              let indexPath = sender.indexPath,
              let cell = tableView.cellForRow(at: indexPath) as? ItemCell else { return }
        let elem = item.elements[indexPath.row]
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
            guard let item = PresetClient().getItemFromName(name: presetName) else { return }
            let itemVC = ItemTagsViewController(item: item)
            navController.pushViewController(itemVC, animated: true)
        case let .multiselect(key, values, _):
            let vc = MultiSelectViewController(values: values, key: key, inputValue: navController.objectProperties[key])
            vc.callbackClosure = { [weak self] newValue in
                guard let self = self else { return }
                if let value = newValue {
                    navController.objectProperties[key] = value
                } else {
                    navController.objectProperties.removeValue(forKey: key)
                }
                self.tableView.reloadData()
            }
            navigationController?.pushViewController(vc, animated: true)
        case let .text(_, key):
            addNewTag(key: key, value: nil)
        case let .check(key, _, valueOn):
            let defValue = valueOn ?? "yes"
            if navController.objectProperties[key] == nil {
                navController.objectProperties[key] = defValue
                cell.rightIcon.icon.image = UIImage(systemName: "checkmark.square")
            } else {
                navController.objectProperties.removeValue(forKey: key)
                cell.rightIcon.icon.image = UIImage(systemName: "square")
            }
        default:
            return
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? ItemCell,
              let navController = navigationController as? CategoryNavigationController
        else {
            return UITableViewCell()
        }
        let data = item.elements[indexPath.row]
        switch data {
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
            cell.button.isHidden = false
            cell.button.selectClosure = nil
            cell.button.indexPath = indexPath
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            if navController.objectProperties[key] == value {
                cell.rightIcon.icon.image = UIImage(systemName: "checkmark.square")
            } else {
                cell.rightIcon.icon.image = UIImage(systemName: "square")
            }
            cell.rightIcon.isHidden = false
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
            cell.button.indexPath = indexPath
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.rightIcon.icon.image = nil
            cell.rightIcon.isHidden = true
            cell.accessoryType = .disclosureIndicator
        case let .text(_, key):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLabel.isHidden = false
            cell.valueLabel.text = navController.objectProperties[key]
            cell.label.isHidden = true
            cell.label.text = nil
            cell.button.indexPath = indexPath
            cell.button.selectClosure = nil
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.button.isHidden = false
            cell.rightIcon.icon.image = UIImage(systemName: "keyboard")
            cell.rightIcon.isHidden = false
            cell.accessoryType = .none
        case let .combo(key, values, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLabel.isHidden = false
            cell.valueLabel.text = navController.objectProperties[key]
            cell.label.text = nil
            cell.label.isHidden = true
            cell.button.isHidden = false
            cell.button.indexPath = indexPath
            cell.configureButton(values: values, curentValue: navController.objectProperties[key])
            cell.button.selectClosure = { [weak self] newValue in
                guard let self = self else { return }
                if newValue == "Custom value" {
                    // TODO:
                    self.addNewTag(key: nil, value: nil)
                } else {
                    navController.objectProperties[key] = newValue
                    cell.valueLabel.text = newValue
                }
                self.tableView.reloadData()
            }
            cell.rightIcon.icon.image = UIImage(systemName: "chevron.down")
            cell.rightIcon.isHidden = false
            cell.accessoryType = .none
        case let .multiselect(key, _, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLabel.isHidden = false
            if var valuesString = navController.objectProperties[key] {
                valuesString = valuesString.replacingOccurrences(of: ";", with: ", ")
                cell.valueLabel.text = valuesString
            } else {
                cell.valueLabel.text = nil
            }
            cell.valueLabel.isHidden = false
            cell.label.isHidden = true
            cell.label.text = nil
            cell.button.indexPath = indexPath
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.button.isHidden = false
            cell.button.selectClosure = nil
            cell.rightIcon.icon.image = nil
            cell.rightIcon.isHidden = true
            cell.accessoryType = .disclosureIndicator
        case let .check(key, text, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            let keyValue = text ?? key
            cell.keyLabel.text = keyValue
            cell.keyLabel.isHidden = false
            cell.valueLabel.isHidden = false
            cell.valueLabel.text = navController.objectProperties[key]
            cell.label.isHidden = true
            cell.label.text = nil
            cell.button.isHidden = false
            cell.button.selectClosure = nil
            cell.button.indexPath = indexPath
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            if navController.objectProperties[key] != nil {
                cell.rightIcon.icon.image = UIImage(systemName: "checkmark.square")
            } else {
                cell.rightIcon.icon.image = UIImage(systemName: "square")
            }
            cell.rightIcon.isHidden = false
            cell.accessoryType = .none
        case let .label(text):
            cell.icon.isHidden = true
            cell.icon.icon.image = nil
            cell.keyLabel.isHidden = true
            cell.keyLabel.text = nil
            cell.valueLabel.isHidden = true
            cell.valueLabel.text = nil
            cell.label.text = text
            cell.label.isHidden = false
            cell.button.isHidden = false
            cell.button.indexPath = indexPath
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.rightIcon.icon.image = nil
            cell.rightIcon.isHidden = true
            cell.accessoryType = .none
        case let .presetLink(presetName):
            if let item = PresetClient().getItemFromName(name: presetName),
               let icon = item.icon
            {
                cell.icon.icon.image = UIImage(named: icon)
                cell.icon.backView.backgroundColor = .white
                cell.icon.isHidden = false
            } else {
                cell.icon.isHidden = true
                cell.icon.icon.image = nil
            }
            cell.keyLabel.isHidden = true
            cell.keyLabel.text = nil
            cell.valueLabel.isHidden = true
            cell.valueLabel.text = nil
            cell.label.isHidden = false
            cell.label.text = presetName
            cell.button.isHidden = false
            cell.button.selectClosure = nil
            cell.button.indexPath = indexPath
            cell.button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            cell.rightIcon.icon.image = nil
            cell.rightIcon.isHidden = true
            cell.accessoryType = .disclosureIndicator
        default:
            cell.icon.isHidden = true
            cell.icon.icon.image = nil
            cell.keyLabel.isHidden = true
            cell.keyLabel.text = nil
            cell.valueLabel.isHidden = true
            cell.valueLabel.text = nil
            cell.label.isHidden = true
            cell.label.text = nil
            cell.button.isHidden = true
            cell.button.selectClosure = nil
            cell.accessoryType = .none
            cell.backgroundColor = .red
        }
        return cell
    }
    
    //  Deleting a previously entered tag.
    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var tagKey: String?
        let data = item.elements[indexPath.row]
        switch data {
        case .link(_), .label(_), .presetLink(_), .reference, .item:
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
                  let key = tagKey,
                  let navController = self.navigationController as? CategoryNavigationController else { return }
            navController.objectProperties.removeValue(forKey: key)
            self.tableView.reloadData()
            completionHandler(true)
        }
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
//    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let navController = navigationController as? CategoryNavigationController,
//              let cell = tableView.cellForRow(at: indexPath) as? ItemCell else { return }
//        let data = item.elements[indexPath.row]
//        switch data {
//        case let .link(wiki):
//            let str = "https://wiki.openstreetmap.org/wiki/" + wiki
//            guard let url = URL(string: str) else { return }
//            let svc = SFSafariViewController(url: url)
//            tableView.deselectRow(at: indexPath, animated: true)
//            present(svc, animated: true, completion: nil)
//        case let .presetLink(presetName):
//            guard let item = getItemFromName(name: presetName) else { return }
//            let vc = ItemTagsViewController(item: item)
//            navigationController?.pushViewController(vc, animated: true)
//        case let .multiselect(key, values, _):
//            let vc = MultiSelectViewController(values: values, key: key, inputValue: navController.objectProperties[key])
//            vc.callbackClosure = { [weak self] newValue in
//                guard let self = self else { return }
//                self.navigationController?.setToolbarHidden(false, animated: false)
//                if let value = newValue {
//                    navController.objectProperties[key] = value
//                } else {
//                    navController.objectProperties.removeValue(forKey: key)
//                }
//                self.tableView.reloadData()
//            }
//            navigationController?.setToolbarHidden(true, animated: false)
//            navigationController?.pushViewController(vc, animated: true)
//        case .combo(_, _, _), .text(_, _), .key:
//            guard let key = cell.keyLabel.text else { return }
//            navigationController?.setToolbarHidden(true, animated: true)
//            addTagView.keyField.text = key
//            addTagView.keyField.isUserInteractionEnabled = false
//            addTagView.valueField.text = cell.valueLabel.text
//            addTagView.isHidden = false
//            addTagView.valueField.becomeFirstResponder()
//        case let .check(key, _, _):
//            navigationController?.setToolbarHidden(true, animated: true)
//            addTagView.keyField.text = key
//            addTagView.keyField.isUserInteractionEnabled = false
//            addTagView.valueField.text = cell.valueLabel.text
//            addTagView.isHidden = false
//            addTagView.valueField.becomeFirstResponder()
//        default:
//            tableView.deselectRow(at: indexPath, animated: true)
//            return
//        }
//    }
}
