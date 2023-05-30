//
//  Table NavigationController objects.swift
//  OSM editor
//
//  Created by Arkadiy on 31.03.2023.
//

import Foundation
import SafariServices
import UIKit

//  Custom SFSafariViewController for calling closure when closing. Use in EditObjectVC
class CustomSafari: SFSafariViewController {
    var callbackClosure: (() -> Void)?
    
    override func viewDidDisappear(_: Bool) {
        guard let clouser = callbackClosure else { return }
        clouser()
    }
}

//  Custom UINavigationController. It opens controllers for displaying saved objects, selecting an object in the case of tapping on several objects, and a tag editing controller.
class NavigationController: UINavigationController {
    var dismissClosure: (() -> Void)?
    
    override func viewDidDisappear(_: Bool) {
        AppSettings.settings.saveAllowed = false
        AppSettings.settings.newProperties = [:]
        guard let clouser = dismissClosure else { return }
        clouser()
    }
}

//  UINavigationController for navigating presets
class CategoryNavigationController: UINavigationController {
    var callbackClosure: (() -> Void)?
    
    override func viewDidDisappear(_: Bool) {
        guard let clouser = callbackClosure else { return }
        clouser()
    }
}

//  Structures for the preset navigation controller
enum CategoryCellType {
    case category
    case group
    case item(tags: [String: String])
}

struct CategoryTableData {
    var type: CategoryCellType
    var icon: String?
    var text: String
}

class IconView: UIView {
    var backView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    var icon: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(backView)
        addSubview(icon)
        let iconWidth = icon.image?.size.width ?? 25
        let iconHeight = icon.image?.size.height ?? 25
        NSLayoutConstraint.activate([
            backView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5),
            backView.widthAnchor.constraint(equalToConstant: 38),
            backView.heightAnchor.constraint(equalToConstant: 38),
            backView.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.centerXAnchor.constraint(equalTo: backView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: iconWidth),
            icon.heightAnchor.constraint(equalToConstant: iconHeight),
        ])
    }
}

class SimpleCell: UITableViewCell {
    var icon: IconView = {
        let view = IconView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.baselineAdjustment = .alignCenters
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    func setupConstrains() {
        contentView.addSubview(icon)
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 44),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            label.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 4),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isUserInteractionEnabled = true
        setupConstrains()
    }
        
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        icon.icon.image = nil
        icon.backView.backgroundColor = .white
        label.text = nil
    }
}

class CategoryCell: UITableViewCell {
    var icon: IconView = {
        let view = IconView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var type: CategoryCellType?
    
    func setupConstrains() {
        contentView.addSubview(icon)
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            icon.topAnchor.constraint(equalTo: contentView.topAnchor),
            icon.widthAnchor.constraint(equalTo: contentView.heightAnchor),
            icon.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            nameLabel.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isUserInteractionEnabled = true
        setupConstrains()
    }
        
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        icon.icon.image = nil
        nameLabel.text = nil
        accessoryType = .none
        type = nil
    }
}

//  Structures for ItemVC
enum ItemCellType {
    case key
    case text
    case combo
    case check
    case label
    case link
    case space
}

class ItemCell: UITableViewCell {
    var icon: IconView = {
        let view = IconView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var keyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var valueLable: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var checkBox: CheckBox = {
        let checkBox = CheckBox()
        checkBox.isChecked = false
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        return checkBox
    }()

    var checkLable: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var selectValueButton: MultiSelectBotton = {
        let button = MultiSelectBotton()
        button.setTitleColor(.label, for: .normal)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var valueField: ValueField = {
        let field = ValueField()
        field.textAlignment = .left
        field.borderStyle = .roundedRect
        field.placeholder = "Enter value"
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    var label: UILabel = {
        let lab = UILabel()
        lab.textAlignment = .left
        lab.numberOfLines = 0
        lab.lineBreakMode = .byWordWrapping
        lab.translatesAutoresizingMaskIntoConstraints = false
        return lab
    }()
        
    func setupConstrains() {
        contentView.addSubview(icon)
        contentView.addSubview(keyLabel)
        contentView.addSubview(valueLable)
        contentView.addSubview(checkBox)
        contentView.addSubview(selectValueButton)
        contentView.addSubview(valueField)
        contentView.addSubview(label)
        contentView.addSubview(checkLable)
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            icon.topAnchor.constraint(equalTo: contentView.topAnchor),
            icon.widthAnchor.constraint(equalTo: icon.backView.widthAnchor),
            icon.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            keyLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            keyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            keyLabel.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            keyLabel.rightAnchor.constraint(equalTo: contentView.centerXAnchor),
            valueLable.leftAnchor.constraint(equalTo: contentView.centerXAnchor),
            valueLable.rightAnchor.constraint(equalTo: checkBox.leftAnchor),
            valueLable.topAnchor.constraint(equalTo: contentView.topAnchor),
            valueLable.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            checkBox.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 50),
            checkBox.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            checkBox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkLable.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            checkLable.topAnchor.constraint(equalTo: contentView.topAnchor),
            checkLable.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            checkLable.rightAnchor.constraint(equalTo: checkBox.leftAnchor, constant: -10),
            selectValueButton.leftAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectValueButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            selectValueButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectValueButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            valueField.leftAnchor.constraint(equalTo: contentView.centerXAnchor),
            valueField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -3),
            valueField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            valueField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10),
            label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isUserInteractionEnabled = true
        setupConstrains()
    }
        
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        icon.icon.image = nil
        icon.isHidden = true
        label.text = nil
        label.isHidden = true
        keyLabel.text = nil
        keyLabel.isHidden = true
        valueLable.text = nil
        valueLable.isHidden = true
        valueField.text = nil
        valueField.isHidden = true
        selectValueButton.menu = nil
        selectValueButton.isHidden = true
        selectValueButton.key = ""
        selectValueButton.values = []
        checkBox.isHidden = true
        checkBox.isChecked = false
        checkLable.text = nil
        checkLable.isHidden = true
        accessoryType = .none
    }
    
    //  The method configures the button to select a value from the list (use on ItemVC and EditObjectVC)
    func configureButton(values: [String]) {
        guard let key = keyLabel.text else { return }
        let optionClosure = { (action: UIAction) in
            if action.title == "" {
                AppSettings.settings.newProperties.removeValue(forKey: key)
            } else {
                AppSettings.settings.newProperties[key] = action.title
            }
        }
        var optionsArray = [UIAction]()
        let nilAction = UIAction(title: "", state: .off, handler: optionClosure)
        for value in values {
            let action = UIAction(title: value, state: .off, handler: optionClosure)
            if value == AppSettings.settings.newProperties[key] {
                nilAction.state = .off
                action.state = .on
                checkBox.isChecked = true
            } else {
                nilAction.state = .on
            }
            optionsArray.append(action)
        }
        optionsArray.append(nilAction)
        let optionsMenu = UIMenu(title: "", image: nil, identifier: nil, options: .singleSelection, children: optionsArray)
        selectValueButton.menu = optionsMenu
        selectValueButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        selectValueButton.showsMenuAsPrimaryAction = true
        selectValueButton.changesSelectionAsPrimaryAction = true
    }
}
