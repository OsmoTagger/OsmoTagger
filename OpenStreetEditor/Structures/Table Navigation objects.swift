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
        guard let closure = dismissClosure else { return }
        closure()
    }

    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool, completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        setViewControllers(viewControllers, animated: animated)
        CATransaction.commit()
    }
}

//  UINavigationController for navigating presets
class CategoryNavigationController: UINavigationController {
    var callbackClosure: (([String: String]) -> Void)?
    var objectProperties: [String: String] = [:]
    
    override func viewDidDisappear(_: Bool) {
        guard let clouser = callbackClosure else { return }
        clouser(objectProperties)
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
        view.layer.cornerRadius = 19
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
    
    var valueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var checkBox: CheckBox = {
        let checkBox = CheckBox()
        checkBox.isChecked = false
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        return checkBox
    }()

    var button: SelectButton = {
        let button = SelectButton()
        button.backgroundColor = .systemBackground
        button.setTitleColor(.label, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        contentView.addSubview(valueLabel)
        contentView.addSubview(checkBox)
        contentView.addSubview(button)
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            icon.widthAnchor.constraint(equalTo: icon.backView.widthAnchor),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            keyLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            keyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            keyLabel.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            keyLabel.rightAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -2),
            keyLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            valueLabel.leftAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 2),
            valueLabel.rightAnchor.constraint(equalTo: checkBox.leftAnchor),
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            checkBox.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 50),
            checkBox.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            checkBox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 50),
            button.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            label.rightAnchor.constraint(equalTo: checkBox.rightAnchor),
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
        valueLabel.text = nil
        valueLabel.isHidden = true
        button.menu = nil
        button.isHidden = true
        button.setImage(nil, for: .normal)
        button.key = ""
        button.values = []
        button.selectClosure = nil
        checkBox.isHidden = true
        checkBox.isChecked = false
        accessoryType = .none
    }
    
    //  The method configures the button to select a value from the list (use on ItemVC and EditObjectVC)
    func configureButton(values: [String], curentValue: String?) {
        let optionClosure = { [weak self] (action: UIAction) in
            guard let self = self else { return }
            if let closure = self.button.selectClosure {
                closure(action.title)
            }
        }
        var optionsArray = [UIAction]()
        let nilAction = UIAction(title: "", state: .off, handler: optionClosure)
        for value in values {
            let action = UIAction(title: value, state: .off, handler: optionClosure)
            if value == curentValue {
                nilAction.state = .off
                action.state = .on
            } else {
                nilAction.state = .on
            }
            optionsArray.append(action)
        }
        optionsArray.append(nilAction)
        let optionsMenu = UIMenu(title: "", image: nil, identifier: nil, options: .singleSelection, children: optionsArray)
        button.menu = optionsMenu
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = false
    }
}
