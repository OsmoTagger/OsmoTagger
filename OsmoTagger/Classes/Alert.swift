//
//  Alert.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 19.09.2023.
//

import UIKit

class Alert: UIView {
    private var circle: UIView = {
        let rv = UIView()
        rv.layer.cornerRadius = 6
        rv.isHidden = true
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()
    
    private var label: UILabel = {
        let rv = UILabel()
        rv.numberOfLines = 0
        rv.font = .systemFont(ofSize: 14)
        rv.textAlignment = .left
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()
    
    init() {
        super.init(frame: .zero)
        setupConstrains()
        backgroundColor = .systemGray5
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4
        alpha = 0.0
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstrains() {
        addSubview(circle)
        addSubview(label)
        NSLayoutConstraint.activate([
            circle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            circle.widthAnchor.constraint(equalToConstant: 12),
            circle.heightAnchor.constraint(equalToConstant: 12),
            circle.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
    }
    
    static func showAlert(text: String, isBad: Bool = false) {
        let alert = Alert()
        alert.label.text = text
        if isBad {
            alert.circle.backgroundColor = .red
            alert.circle.isHidden = false
            if alert.label.text != nil {
                alert.label.text! += "\nShow logs..."
            }
        } else {
            alert.circle.backgroundColor = .systemGreen
            alert.circle.isHidden = false
        }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let window = windowScene.windows.first {
                window.addSubview(alert)
                NSLayoutConstraint.activate([
                    alert.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
                    alert.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
                    alert.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor),
                    alert.leadingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.leadingAnchor),
                ])
                        
                UIView.animate(withDuration: 0.5, animations: { [weak alert] in
                    alert?.alpha = 1
                }, completion: { [weak alert] _ in
                    UIView.animate(withDuration: 0.5, delay: 7, animations: {
                        alert?.alpha = 0
                    }, completion: { [weak alert] _ in
                        alert?.removeFromSuperview()
                    })
                })
            }
        }
    }
}
