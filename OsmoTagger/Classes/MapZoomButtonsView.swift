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
    var plusButton: MapButton = {
        let rv = MapButton()
        rv.configure(image: "plus")
        return rv
    }()
    
    var minusButton: MapButton = {
        let rv = MapButton()
        rv.configure(image: "minus")
        return rv
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
