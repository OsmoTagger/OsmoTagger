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
class ItemTagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate {
    var item: Item
    
    var tableView = UITableView()
    var cellId = "cell"
    var tableConstraints = [NSLayoutConstraint]()
    
    var iconTypes: [UIBarButtonItem] = []
    var doneButtonForBar = UIBarButtonItem()
    
    var tap = UITapGestureRecognizer()
    
    init(item: Item) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = item.name
        prepareElements()
        
//      Notifications when calling and hiding the keyboard.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
//      Set RightBarItems
        doneButtonForBar = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDoneButton))
        iconTypes = [doneButtonForBar]
        addIconTypes()
        navigationItem.setRightBarButtonItems(iconTypes, animated: true)
        
        tableConstraints = [tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
                            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                            tableView.topAnchor.constraint(equalTo: view.topAnchor)]
        setTableView()
    }
    
    override func viewDidDisappear(_: Bool) {}
    
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
                iconName = "osm_element_area"
            }
            iconType.image = UIImage(named: iconName)
            let iconTypeForBar = UIBarButtonItem(customView: iconType)
            iconTypes.insert(iconTypeForBar, at: 1)
        }
    }
    
    @objc func tapDoneButton() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return item.elements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? ItemCell else {
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
            cell.valueLable.text = value
            cell.valueLable.isHidden = false
            cell.valueField.isHidden = true
            cell.label.isHidden = true
            cell.checkLable.isHidden = true
            cell.checkBox.isHidden = false
            cell.checkBox.addTarget(self, action: #selector(tapCheckBox), for: .touchUpInside)
            cell.checkBox.indexPath = indexPath
            if AppSettings.settings.newProperties[key] == value {
                cell.checkBox.isChecked = true
            }
            cell.selectValueButton.isHidden = true
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
        case let .multiselect(key, _, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLable.isHidden = false
            if let inputValuesString = AppSettings.settings.newProperties[key] {
                let inputValues = inputValuesString.components(separatedBy: ";")
                var text = ""
                for value in inputValues {
                    text +=  value + "\n"
                }
                text.removeLast()
                cell.valueLable.text = text
            }
            cell.valueField.isHidden = true
            cell.checkLable.isHidden = true
            cell.checkBox.isHidden = true
            cell.selectValueButton.isHidden = true
            cell.accessoryType = .disclosureIndicator
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
        case let .presetLink(presetName):
            guard let item = getItemFromName(name: presetName) else {
                let cellFail = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
                cellFail.textLabel?.text = "Point data loading error"
                return cellFail
            }
            if let icon = item.icon {
                cell.icon.icon.image = UIImage(named: icon)
                cell.icon.backView.backgroundColor = .white
                cell.icon.isHidden = false
            } else {
                cell.icon.isHidden = true
            }
            cell.keyLabel.isHidden = true
            cell.valueLable.isHidden = true
            cell.valueField.isHidden = true
            cell.checkLable.text = item.name
            cell.checkLable.isHidden = false
            cell.checkBox.isHidden = true
            cell.label.isHidden = true
            cell.selectValueButton.isHidden = true
            cell.accessoryType = .disclosureIndicator
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
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = item.elements[indexPath.row]
        switch data {
        case let .link(wiki):
            let str = "https://wiki.openstreetmap.org/wiki/" + wiki
            guard let url = URL(string: str) else { return }
            let svc = SFSafariViewController(url: url)
            tableView.deselectRow(at: indexPath, animated: true)
            present(svc, animated: true, completion: nil)
        case let .presetLink(presetName):
            guard let item = getItemFromName(name: presetName) else { return }
            let vc = ItemTagsViewController(item: item)
            navigationController?.pushViewController(vc, animated: true)
        case let .multiselect(key, values, _):
            let vc = MultiSelectViewController(values: values, key: key)
            vc.callbackClosure = { [weak self] in
                guard let self = self else {return}
                self.navigationController?.setToolbarHidden(false, animated: false)
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
            navigationController?.setToolbarHidden(true, animated: false)
            navigationController?.pushViewController(vc, animated: true)
        default:
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
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
    
    @objc func tapCheckBox(sender: CheckBox) {
        sender.isChecked = !sender.isChecked
        let elem = item.elements[sender.indexPath.row]
        switch elem {
        case let .key(key, value):
            if sender.isChecked {
                AppSettings.settings.newProperties[key] = value
            } else {
                AppSettings.settings.newProperties.removeValue(forKey: key)
            }
        case let .check(key, _, valueOn):
            let def = valueOn ?? "yes"
            if sender.isChecked {
                AppSettings.settings.newProperties[key] = def
            } else {
                AppSettings.settings.newProperties.removeValue(forKey: key)
            }
        default:
            showAction(message: "Bad index of element", addAlerts: [])
        }
    }
    
    //  Methods for saving the entered UITextField value.
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
        finishEdit(textField)
        view.removeGestureRecognizer(tap)
    }
    
    func finishEdit(_ textField: UITextField) {
        if let textField = textField as? ValueField {
            guard let key = textField.key else {
                return
            }
            if textField.text == "" {
                AppSettings.settings.newProperties.removeValue(forKey: key)
            } else {
                AppSettings.settings.newProperties[key] = textField.text
            }
        }
    }
    
    //  View offset when calling and hiding the keyboard.
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if keyboardSize.height > 0 {
            NSLayoutConstraint.deactivate(tableConstraints)
            tableConstraints = [tableView.topAnchor.constraint(equalTo: view.topAnchor),
                                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboardSize.height),
                                tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                                tableView.leftAnchor.constraint(equalTo: view.leftAnchor)]
            NSLayoutConstraint.activate(tableConstraints)
        }
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        NSLayoutConstraint.deactivate(tableConstraints)
        tableConstraints = [tableView.topAnchor.constraint(equalTo: view.topAnchor),
                            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
                            tableView.leftAnchor.constraint(equalTo: view.leftAnchor)]
        NSLayoutConstraint.activate(tableConstraints)
    }
    
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool { return true }
}
