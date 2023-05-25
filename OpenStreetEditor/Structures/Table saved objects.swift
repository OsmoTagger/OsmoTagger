//
//  Table saved objects.swift
//  OSM editor
//
//  Created by Arkadiy on 31.03.2023.
//

import Foundation
import UIKit

// Structures for SavedNodesVC (controller for displaying saved objects)
struct SaveNodeTableData {
    var name: String?
    var items: [SaveNodeCellData]
}

struct SavedSelectedIndex: Equatable {
    let type: SavedObjectType
    let id: Int
}

enum SavedObjectType {
    case saved
    case deleted
}

struct SaveNodeCellData {
    let type: SavedObjectType
    var itemIcon: String?
    let typeIcon: String
    var itemLabel: String?
    let idLabel: Int
}

class SavedNodeCell: UITableViewCell {
    var iconItem: IconView = {
        let view = IconView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var iconType: IconView = {
        let image = IconView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var itemLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var idLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var checkBox: CheckBox = {
        let checkBox = CheckBox()
        checkBox.isChecked = false
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        return checkBox
    }()

    var bulb: MultiSelectBotton = {
        let bulb = MultiSelectBotton()
        bulb.setImage(UIImage(systemName: "lightbulb")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal), for: .normal)
        bulb.translatesAutoresizingMaskIntoConstraints = false
        return bulb
    }()
    
    func setupConstrains() {
        contentView.addSubview(iconItem)
        contentView.addSubview(iconType)
        contentView.addSubview(itemLabel)
        contentView.addSubview(idLabel)
        contentView.addSubview(checkBox)
        contentView.addSubview(bulb)
        NSLayoutConstraint.activate([
            iconItem.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            iconItem.widthAnchor.constraint(equalToConstant: 44),
            iconItem.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconType.leftAnchor.constraint(equalTo: iconItem.rightAnchor),
            iconType.widthAnchor.constraint(equalToConstant: 44),
            iconType.heightAnchor.constraint(equalToConstant: 44),
            iconType.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            itemLabel.leftAnchor.constraint(equalTo: iconType.rightAnchor, constant: 5),
            itemLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            itemLabel.rightAnchor.constraint(equalTo: checkBox.leftAnchor),
            itemLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor),
            idLabel.leftAnchor.constraint(equalTo: iconType.rightAnchor, constant: 5),
            idLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor),
            idLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            idLabel.rightAnchor.constraint(equalTo: checkBox.leftAnchor),
            checkBox.rightAnchor.constraint(equalTo: bulb.leftAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 50),
            checkBox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            bulb.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bulb.widthAnchor.constraint(equalToConstant: 45),
            bulb.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            bulb.rightAnchor.constraint(equalTo: contentView.rightAnchor),
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
        iconItem.icon.image = nil
        iconType.icon.image = nil
        itemLabel.text = nil
        idLabel.text = nil
        checkBox.isChecked = false
        bulb.key = nil
    }
}
