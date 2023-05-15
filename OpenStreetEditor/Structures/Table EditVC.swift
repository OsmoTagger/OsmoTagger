//
//  Tbale EditVC.swift
//  OSM editor
//
//  Created by Arkadiy on 31.03.2023.
//

import Foundation
import UIKit

//  Structures for EditObjectVC
struct EditSectionData {
    let name: String
    var items: [ItemElements]
}

enum EditCellType {
    case item
    case tag
}

struct EditCellData {
    var type: EditCellType
    var icon: String?
    var key: String?
    var value: String?
    var text: String?
    var path: ItemPath?
}

class EditPropertiesCell: UITableViewCell {
    var icon: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    var keyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var valueField: ValueField = {
        let field = ValueField()
        field.textAlignment = .left
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var itemPath: ItemPath?
    
    func setupConstrains() {
        contentView.addSubview(icon)
        contentView.addSubview(keyLabel)
        contentView.addSubview(valueField)
        contentView.addSubview(label)
        let iconWidth = icon.image?.size.width ?? 25
        let iconHeight = icon.image?.size.height ?? 25
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: iconWidth),
            icon.heightAnchor.constraint(equalToConstant: iconHeight),
            keyLabel.topAnchor.constraint(equalTo: topAnchor),
            keyLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            keyLabel.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            keyLabel.rightAnchor.constraint(equalTo: centerXAnchor),
            valueField.leftAnchor.constraint(equalTo: centerXAnchor),
            valueField.rightAnchor.constraint(equalTo: rightAnchor),
            valueField.topAnchor.constraint(equalTo: topAnchor),
            valueField.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.rightAnchor.constraint(equalTo: rightAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
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
        icon.image = nil
        keyLabel.text = nil
        valueField.text = nil
        valueField.key = nil
        valueField.indexPath = nil
    }
}
