//
//  SimpleCell.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
//

import Foundation
import UIKit

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
