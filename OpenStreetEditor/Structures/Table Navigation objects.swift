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
    var path: ItemPath?
}

class RightIconView: UIView {
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
        NSLayoutConstraint.activate([
            backView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5),
            backView.widthAnchor.constraint(equalToConstant: 38),
            backView.heightAnchor.constraint(equalToConstant: 38),
            backView.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.centerXAnchor.constraint(equalTo: backView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
        ])
    }
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
    
    var bigLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var smallLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var pathLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var type: CategoryCellType?
    
    func setupConstrains() {
        contentView.addSubview(icon)
        contentView.addSubview(bigLabel)
        contentView.addSubview(smallLabel)
        contentView.addSubview(pathLabel)
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            icon.topAnchor.constraint(equalTo: contentView.topAnchor),
            icon.widthAnchor.constraint(equalTo: contentView.heightAnchor),
            icon.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bigLabel.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            bigLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
            bigLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            bigLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            smallLabel.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            smallLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            smallLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 10),
            smallLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
            pathLabel.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            pathLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -3),
            pathLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pathLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
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
        bigLabel.text = nil
        bigLabel.isHidden = true
        smallLabel.text = nil
        smallLabel.isHidden = true
        pathLabel.text = nil
        pathLabel.isHidden = true
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

    var button: SelectButton = {
        let button = SelectButton()
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
    
    var rightIcon: RightIconView = {
        let icon = RightIconView()
        icon.backView.backgroundColor = .systemBackground
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()
        
    func setupConstrains() {
        contentView.addSubview(icon)
        contentView.addSubview(keyLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(button)
        contentView.addSubview(label)
        contentView.addSubview(rightIcon)
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
            valueLabel.rightAnchor.constraint(equalTo: rightIcon.leftAnchor),
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            button.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            label.rightAnchor.constraint(equalTo: rightIcon.rightAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            rightIcon.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
            rightIcon.widthAnchor.constraint(equalTo: rightIcon.backView.widthAnchor),
            rightIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
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
        button.indexPath = nil
        rightIcon.icon.image = nil
        rightIcon.isHidden = true
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
        let customAction = UIAction(title: "Custom value", image: UIImage(systemName: "pencil"), identifier: nil, discoverabilityTitle: "nil", attributes: .destructive, state: .off, handler: optionClosure)
        for value in values {
            let action = UIAction(title: value, state: .off, handler: optionClosure)
            if value == curentValue {
                action.state = .on
            }
            optionsArray.append(action)
        }
        optionsArray.append(customAction)
        let optionsMenu = UIMenu(title: "", image: nil, identifier: nil, options: .singleSelection, children: optionsArray)
        button.menu = optionsMenu
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = false
    }
}
