//
//  SecreenSettingsCell.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 27.07.2023.
//

import Foundation
import UIKit

struct ScreenSettingsCellData {
    let icon: String
    let mainText: String
    let toogleIsOn: Bool
}

class ScreenSettingsCell: UITableViewCell {
    var icon: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 5
        view.layer.borderColor = UIColor.systemGray.cgColor
        view.layer.borderWidth = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var mainLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var toogle: UISwitch = {
        let switcher = UISwitch()
        switcher.isUserInteractionEnabled = false
        switcher.translatesAutoresizingMaskIntoConstraints = false
        return switcher
    }()
    
    private func setupConstrains() {
        contentView.addSubview(icon)
        contentView.addSubview(mainLabel)
        contentView.addSubview(toogle)
        let iconSize: CGFloat = 150
        NSLayoutConstraint.activate([
            icon.heightAnchor.constraint(equalToConstant: iconSize),
            icon.widthAnchor.constraint(equalToConstant: iconSize),
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            mainLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 5),
            mainLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            mainLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            mainLabel.trailingAnchor.constraint(equalTo: toogle.leadingAnchor, constant: -5),
            toogle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            toogle.widthAnchor.constraint(equalToConstant: 50),
            toogle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
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
        mainLabel.text = nil
        toogle.isOn = false
    }
    
}
