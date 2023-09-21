//
//  MapButtons.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
//

import Foundation
import UIKit

// zoom plus, minus, set map angle
class MapZoomButtonsView: UIView {
    var plusButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 5
        button.backgroundColor = .white
        button.setImage(UIImage(systemName: "plus")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var minusButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 5
        button.backgroundColor = .white
        button.setImage(UIImage(systemName: "minus")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var angleButton: AngleButton = {
        let button = AngleButton()
        button.layer.cornerRadius = 5
        button.backgroundColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    convenience init() {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupConstrains()
        
        // When the parameter is changed in the settings, a closure is triggered in which we modify isHidden.
        isHidden = AppSettings.settings.mapButtonsIsHidden
        AppSettings.settings.showMapButtonsClosure = { [weak self] newValue in
            guard let self = self else { return }
            self.isHidden = newValue
        }
    }
    
    private func setupConstrains() {
        addSubview(plusButton)
        addSubview(minusButton)
        addSubview(angleButton)
        NSLayoutConstraint.activate([
            plusButton.widthAnchor.constraint(equalToConstant: 40),
            plusButton.heightAnchor.constraint(equalToConstant: 40),
            plusButton.topAnchor.constraint(equalTo: topAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 40),
            minusButton.heightAnchor.constraint(equalToConstant: 40),
            minusButton.topAnchor.constraint(equalTo: plusButton.bottomAnchor, constant: 15),
            angleButton.widthAnchor.constraint(equalToConstant: 40),
            angleButton.heightAnchor.constraint(equalToConstant: 40),
            angleButton.topAnchor.constraint(equalTo: minusButton.bottomAnchor, constant: 15),
        ])
    }
}
