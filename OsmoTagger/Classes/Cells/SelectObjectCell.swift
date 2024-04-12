//
//  SelectObjectCell.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
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
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
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
    
    func setupConstrains() {
        contentView.addSubview(iconItem)
        contentView.addSubview(iconType)
        contentView.addSubview(itemLabel)
        contentView.addSubview(idLabel)
        let iconTypeWidth = iconType.image?.size.width ?? 25
        let iconTypeHeight = iconType.image?.size.height ?? 25
        NSLayoutConstraint.activate([
            iconItem.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            iconItem.widthAnchor.constraint(equalToConstant: 44),
            iconItem.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconType.leadingAnchor.constraint(equalTo: iconItem.trailingAnchor, constant: 10),
            iconType.widthAnchor.constraint(equalToConstant: iconTypeWidth),
            iconType.heightAnchor.constraint(equalToConstant: iconTypeHeight),
            iconType.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            itemLabel.leadingAnchor.constraint(equalTo: iconType.trailingAnchor, constant: 10),
            itemLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            itemLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            itemLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor),
            idLabel.leadingAnchor.constraint(equalTo: iconType.trailingAnchor, constant: 10),
            idLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor),
            idLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            idLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
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
    }
}
