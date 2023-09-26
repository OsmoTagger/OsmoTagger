//
//  EditCell.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 24.09.2023.
//

import Foundation
import UIKit

class EditCell: UITableViewCell {
    var icon: IconView = {
        let rv = IconView()
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()

    var keyLabel: UILabel = {
        let rv = UILabel()
        rv.numberOfLines = 0
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()

    var valueLabel: UILabel = {
        let rv = UILabel()
        rv.numberOfLines = 0
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()

    var titleLabel: UILabel = {
        let rv = UILabel()
        rv.numberOfLines = 0
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isUserInteractionEnabled = true
        setupConstrains()
    }
        
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstrains() {
        contentView.addSubview(icon)
        contentView.addSubview(keyLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            
            icon.widthAnchor.constraint(equalToConstant: 44),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            
            keyLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 4),
            keyLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            keyLabel.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -2),
            keyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            valueLabel.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 2),
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 4),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -50),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    func configure(data: ItemElements) {
        switch data {
        case let .item(path):
            guard let item = PresetClient().getItemFromPath(path: path) else { return }
            if let iconName = item.icon {
                icon.isHidden = false
                icon.backView.backgroundColor = .white
                icon.icon.image = UIImage(named: iconName)
            } else {
                icon.isHidden = true
            }
            keyLabel.isHidden = true
            valueLabel.isHidden = true
            titleLabel.isHidden = false
            titleLabel.text = item.name
            accessoryType = .disclosureIndicator
        case let .key(key, value):
            icon.isHidden = false
            icon.icon.image = UIImage(systemName: "tag")
            icon.backView.backgroundColor = .systemBackground
            keyLabel.isHidden = false
            keyLabel.text = key
            valueLabel.isHidden = false
            valueLabel.text = value
            titleLabel.isHidden = true
            accessoryType = .none
        default:
            return
        }
    }
    
    override func prepareForReuse() {
        icon.icon.image = nil
        icon.backView.backgroundColor = .white
        keyLabel.text = nil
        valueLabel.text = nil
        titleLabel.text = nil
        accessoryType = .none
    }
}
