//
//  Table SelectVC.swift
//  OSM editor
//
//  Created by Arkadiy on 31.03.2023.
//

import Foundation
import UIKit

// Structures for SelectObjectVC
struct SelectObjectCellData {
    var iconItem: String?
    let type: OSMObjectType
    var itemLabel: String?
    var idLabel: String
}

class SelectObjectCell: UITableViewCell {
    var iconItem: IconView = {
        let view = IconView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var iconType: UIImageView = {
        let image = UIImageView()
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
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        contentView.addSubview(bulb)
        let iconTypeWidth = iconType.image?.size.width ?? 25
        let iconTypeHeight = iconType.image?.size.height ?? 25
        NSLayoutConstraint.activate([
            iconItem.leftAnchor.constraint(equalTo: leftAnchor),
            iconItem.widthAnchor.constraint(equalTo: heightAnchor),
            iconItem.topAnchor.constraint(equalTo: topAnchor),
            iconItem.bottomAnchor.constraint(equalTo: bottomAnchor),
            iconType.leftAnchor.constraint(equalTo: iconItem.rightAnchor, constant: 10),
            iconType.widthAnchor.constraint(equalToConstant: iconTypeWidth),
            iconType.heightAnchor.constraint(equalToConstant: iconTypeHeight),
            iconType.centerYAnchor.constraint(equalTo: centerYAnchor),
            itemLabel.leftAnchor.constraint(equalTo: iconType.rightAnchor, constant: 10),
            itemLabel.topAnchor.constraint(equalTo: topAnchor),
            itemLabel.rightAnchor.constraint(equalTo: centerXAnchor),
            itemLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            idLabel.leftAnchor.constraint(equalTo: itemLabel.rightAnchor),
            idLabel.topAnchor.constraint(equalTo: topAnchor),
            idLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            idLabel.rightAnchor.constraint(equalTo: bulb.leftAnchor),
            bulb.rightAnchor.constraint(equalTo: rightAnchor),
            bulb.bottomAnchor.constraint(equalTo: bottomAnchor),
            bulb.widthAnchor.constraint(equalToConstant: 50),
            bulb.topAnchor.constraint(equalTo: topAnchor),
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
        iconType.image = nil
        itemLabel.text = nil
        idLabel.text = nil
        bulb.key = nil
    }
}
