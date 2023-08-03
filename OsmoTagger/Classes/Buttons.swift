//
//  Buttons.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
//

import Foundation
import UIKit

// DrawButton on MapViewController
class DrawButton: UIButton {
    var isActive = false {
        didSet {
            if isActive {
                backgroundColor = .systemGray3
            } else {
                backgroundColor = .white
            }
        }
    }
}

// Custom button for download button on the map
class DownloadButton: UIButton {
    let circle: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.isHidden = true
        view.backgroundColor = .systemGreen
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupConstrains()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstrains() {
        addSubview(circle)
        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: 12),
            circle.heightAnchor.constraint(equalToConstant: 12),
            circle.centerXAnchor.constraint(equalTo: rightAnchor, constant: -8),
            circle.centerYAnchor.constraint(equalTo: topAnchor, constant: 8),
        ])
    }
}

//  Custom button for switching to the controller of saved objects
class SavedObjectButton: UIButton {
    private let circle: UIView = {
        let view = UIView()
        let counts = AppSettings.settings.savedObjects.count + AppSettings.settings.deletedObjects.count
        if counts == 0 {
            view.isHidden = true
        } else {
            view.isHidden = false
            view.backgroundColor = .systemRed
        }
        view.layer.cornerRadius = 9
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.text = String(AppSettings.settings.savedObjects.count + AppSettings.settings.deletedObjects.count)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var lastCount = AppSettings.settings.savedObjects.count + AppSettings.settings.deletedObjects.count

    init() {
        super.init(frame: .zero)
        setupConstrains()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstrains() {
        addSubview(circle)
        addSubview(label)
        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: 18),
            circle.heightAnchor.constraint(equalToConstant: 18),
            circle.centerXAnchor.constraint(equalTo: rightAnchor, constant: -3),
            circle.centerYAnchor.constraint(equalTo: topAnchor, constant: 3),
            label.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
        ])
    }
    
    // Method update count and of saved, created and deleted objects
    func update() {
        let counts = AppSettings.settings.savedObjects.count + AppSettings.settings.deletedObjects.count
        guard lastCount != counts else { return }
        if lastCount == 0 {
            circle.isHidden = false
        }
        lastCount = counts
        UIView.animate(withDuration: 0.4, animations: {
            self.circle.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.label.transform = CGAffineTransform(rotationAngle: -.pi)
        }) { _ in
            UIView.animate(withDuration: 0.4) {
                self.circle.transform = .identity
                self.label.transform = .identity
            } completion: { _ in
                if counts == 0 {
                    self.circle.isHidden = true
                    self.label.text = nil
                } else {
                    self.circle.backgroundColor = .systemRed
                    self.label.text = String(counts)
                }
            }
        }
    }
}

// The button that is used to select the tag values from the list. Used on the tag editing controller and ItemVC
class SelectButton: UIButton {
    var selectClosure: ((String) -> Void)?
    var key: String?
    var values: [String] = []
    var indexPath: IndexPath?
}

// Angle button in MapButtonsView on MapVC
class AngleButton: UIView {
    var image: UIImageView = {
        let icon = UIImageView()
        icon.image = UIImage(systemName: "location.north.line.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal)
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()
    
    convenience init() {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(image)
        NSLayoutConstraint.activate([
            image.centerXAnchor.constraint(equalTo: centerXAnchor),
            image.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
