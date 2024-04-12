//
//  KeyValueEditCell.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 24.09.2023.
//

import Foundation
import UIKit

class KeyValueEditCell: UITableViewCell {
    var icon: UIImageView = {
        let rv = UIImageView()
        rv.image = UIImage(systemName: "tag")
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
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            
            keyLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 4),
            keyLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            keyLabel.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -2),
            keyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            valueLabel.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 2),
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    func configure(data: ItemElements) {
        switch data {
        case let .key(key, value):
            icon.isHidden = false
            keyLabel.isHidden = false
            keyLabel.text = key
            valueLabel.isHidden = false
            valueLabel.text = value
            accessoryType = .none
        default:
            return
        }
    }
    
    override func prepareForReuse() {
        keyLabel.text = nil
        valueLabel.text = nil
        accessoryType = .none
    }
}
