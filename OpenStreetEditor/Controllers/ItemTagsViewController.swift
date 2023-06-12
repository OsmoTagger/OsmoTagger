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
class ItemTagsViewController: UIViewController {
    var item: Item
    
    var tableView = UITableView()
    var cellId = "cell"
    
    var iconTypes: [UIBarButtonItem] = []
    var doneButtonForBar = UIBarButtonItem()
    
    //  The view that is displayed when manually entering text.
    var addTagView = AddTagManuallyView()
    var addViewBottomConstraint = NSLayoutConstraint()
    
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
                
//      Set RightBarItems
        doneButtonForBar = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDoneButton))
        iconTypes = [doneButtonForBar]
        addIconTypes()
        navigationItem.setRightBarButtonItems(iconTypes, animated: true)
        
        setTableView()
        setEnterTagManuallyView()
    }
    
    override func viewWillAppear(_: Bool) {
        // Notifications when calling and hiding the keyboard.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setEnterTagManuallyView() {
        //  When the tag is entered manually, addView.callbackClosure is triggered, which passes the entered tag=value pair. The table data is updated.
        addTagView.callbackClosure = { [weak self] addedTag in
            guard let self = self else { return }
            self.view.endEditing(true)
            self.addTagView.isHidden = true
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
    
    @objc func tapKeyBoard(_ sender: SelectButton) {
        guard let key = sender.key else { return }
        addTagView.keyField.text = key
        addTagView.keyField.isUserInteractionEnabled = false
        addTagView.valueField.text = AppSettings.settings.newProperties[key]
        addTagView.isHidden = false
        addTagView.valueField.becomeFirstResponder()
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
    
    //  View offset when calling and hiding the keyboard.
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if keyboardSize.height > 0 {
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                guard let self = self else { return }
                self.addViewBottomConstraint.constant = -keyboardSize.height + self.view.safeAreaInsets.bottom
            })
        }
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self = self else { return }
            self.addViewBottomConstraint.constant = 0
        })
    }
}

extension ItemTagsViewController: UITableViewDataSource, UITableViewDelegate {
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
            cell.valueLabel.text = value
            cell.valueLabel.isHidden = false
            cell.label.isHidden = true
            cell.checkBox.isHidden = false
            cell.checkBox.addTarget(self, action: #selector(tapCheckBox), for: .touchUpInside)
            cell.checkBox.indexPath = indexPath
            if AppSettings.settings.newProperties[key] == value {
                cell.checkBox.isChecked = true
            }
            cell.button.isHidden = true
            cell.accessoryType = .none
        case let .link(wiki):
            cell.icon.icon.image = UIImage(named: "osm_wiki_logo")
            cell.icon.backView.backgroundColor = .white
            cell.icon.isHidden = false
            cell.keyLabel.text = wiki
            cell.keyLabel.isHidden = true
            cell.valueLabel.isHidden = true
            cell.label.isHidden = false
            cell.label.text = "Open wiki"
            cell.checkBox.isHidden = true
            cell.button.isHidden = true
            cell.accessoryType = .disclosureIndicator
        case let .text(_, key):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLabel.isHidden = false
            cell.valueLabel.text = AppSettings.settings.newProperties[key]
            cell.label.isHidden = true
            cell.checkBox.isHidden = true
            cell.button.setImage(UIImage(systemName: "keyboard"), for: .normal)
            cell.button.key = key
            cell.button.addTarget(self, action: #selector(tapKeyBoard), for: .touchUpInside)
            cell.button.isHidden = false
            cell.accessoryType = .none
        case let .combo(key, values, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLabel.isHidden = false
            cell.valueLabel.text = AppSettings.settings.newProperties[key]
            cell.checkBox.isHidden = true
            cell.button.isHidden = false
            cell.button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            cell.configureButton(values: values)
            cell.accessoryType = .none
        case let .multiselect(key, _, _):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            cell.keyLabel.text = key
            cell.keyLabel.isHidden = false
            cell.valueLabel.isHidden = false
            if var valuesString = AppSettings.settings.newProperties[key] {
                valuesString = valuesString.replacingOccurrences(of: ";", with: ", ")
                cell.valueLabel.text = valuesString
            } else {
                cell.valueLabel.text = nil
            }
            cell.valueLabel.isHidden = false
            cell.label.isHidden = true
            cell.checkBox.isHidden = true
            cell.button.isHidden = true
            cell.accessoryType = .disclosureIndicator
        case let .check(key, text, valueOn):
            cell.icon.icon.image = UIImage(systemName: "tag")
            cell.icon.backView.backgroundColor = .systemBackground
            cell.icon.isHidden = false
            let keyValue = text ?? key
            cell.keyLabel.text = keyValue
            cell.keyLabel.isHidden = false
            cell.valueLabel.isHidden = true
            cell.label.isHidden = true
            cell.checkBox.isHidden = false
            cell.checkBox.indexPath = indexPath
            cell.checkBox.addTarget(self, action: #selector(tapCheckBox), for: .touchUpInside)
            if AppSettings.settings.newProperties[key] != nil {
                cell.checkBox.isChecked = true
            } else {
                cell.checkBox.isChecked = false
            }
            cell.button.isHidden = true
            cell.accessoryType = .none
        case let .label(text):
            cell.icon.isHidden = true
            cell.keyLabel.isHidden = true
            cell.valueLabel.isHidden = true
            cell.checkBox.isHidden = true
            cell.label.text = text
            cell.label.isHidden = false
            cell.button.isHidden = true
            cell.accessoryType = .none
        case let .presetLink(presetName):
            if let item = getItemFromName(name: presetName) {
                if let icon = item.icon {
                    cell.icon.icon.image = UIImage(named: icon)
                    cell.icon.backView.backgroundColor = .white
                    cell.icon.isHidden = false
                } else {
                    cell.icon.isHidden = true
                }
            }
            cell.keyLabel.isHidden = true
            cell.valueLabel.isHidden = true
            cell.label.isHidden = false
            cell.label.text = presetName
            cell.checkBox.isHidden = true
            cell.button.isHidden = true
            cell.accessoryType = .disclosureIndicator
        default:
            cell.icon.isHidden = true
            cell.keyLabel.isHidden = true
            cell.valueLabel.isHidden = true
            cell.checkBox.isHidden = true
            cell.label.isHidden = true
            cell.button.isHidden = true
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
                guard let self = self else { return }
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
}
