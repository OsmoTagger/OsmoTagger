//
//  ItemCell.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
//

import Foundation
import UIKit

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
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            icon.widthAnchor.constraint(equalTo: icon.backView.widthAnchor),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            keyLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            keyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            keyLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            keyLabel.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -2),
            keyLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            valueLabel.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 2),
            valueLabel.trailingAnchor.constraint(equalTo: rightIcon.leadingAnchor),
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: rightIcon.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            rightIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
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
