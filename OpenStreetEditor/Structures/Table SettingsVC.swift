//
//  Table SettingsVC.swift
//  OSM editor
//
//  Created by Arkadiy on 12.04.2023.
//

import Foundation
import UIKit

//  Structures for Settings controllers
struct SettingsTableData {
    let name: String?
    let items: [SettingsCellData]
}

struct SettingsCellData {
    let icon: String
    let text: String
    let link: String
}

class SettingsTitleView: UIView {
    var icon: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 18)
        label.baselineAdjustment = .alignCenters
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(icon)
        addSubview(label)
        let iconSize = CGFloat(18)
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: iconSize),
            icon.widthAnchor.constraint(equalToConstant: iconSize),
            label.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 5),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -7),
        ])
    }
}
