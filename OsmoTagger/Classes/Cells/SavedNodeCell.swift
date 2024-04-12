//
//  SavedNodeCell.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
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
    
    func setupConstrains() {
        contentView.addSubview(iconItem)
        contentView.addSubview(iconType)
        contentView.addSubview(itemLabel)
        contentView.addSubview(idLabel)
        contentView.addSubview(checkBox)
        NSLayoutConstraint.activate([
            iconItem.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            iconItem.widthAnchor.constraint(equalToConstant: 44),
            iconItem.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconType.leadingAnchor.constraint(equalTo: iconItem.trailingAnchor),
            iconType.widthAnchor.constraint(equalToConstant: 44),
            iconType.heightAnchor.constraint(equalToConstant: 44),
            iconType.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            itemLabel.leadingAnchor.constraint(equalTo: iconType.trailingAnchor, constant: 5),
            itemLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            itemLabel.trailingAnchor.constraint(equalTo: checkBox.leadingAnchor),
            itemLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor),
            idLabel.leadingAnchor.constraint(equalTo: iconType.trailingAnchor, constant: 5),
            idLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor),
            idLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            idLabel.trailingAnchor.constraint(equalTo: checkBox.leadingAnchor),
            checkBox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 50),
            checkBox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
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
    }
}
