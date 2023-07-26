//
//  CategoryCell.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
//

import Foundation
import UIKit


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
