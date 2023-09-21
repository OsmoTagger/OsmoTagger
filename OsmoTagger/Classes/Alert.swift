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
        rv.layer.cornerRadius = 8
        rv.isHidden = true
        rv.isUserInteractionEnabled = true
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()
    
    private var label: UILabel = {
        let rv = UILabel()
        rv.numberOfLines = 0
        rv.font = .systemFont(ofSize: 16)
        rv.textAlignment = .left
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()
    
    var callbackClosure: EmptyBlock?
    
    init() {
        super.init(frame: .zero)
        setupConstrains()
        backgroundColor = .systemGray5
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4
        alpha = 0.0
        
        let swipeGuest = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
        swipeGuest.direction = .up
        swipeGuest.delegate = self
        addGestureRecognizer(swipeGuest)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func swipe() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.callbackClosure?()
            self?.alpha = 0.0
        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
        })
    }
    
    private func setupConstrains() {
        addSubview(circle)
        addSubview(label)
        NSLayoutConstraint.activate([
            circle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            circle.widthAnchor.constraint(equalToConstant: 16),
            circle.heightAnchor.constraint(equalToConstant: 16),
            circle.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
    }
    
    static func showAlert(_ text: String, isBad: Bool = true) {
        let alert = Alert()
        alert.label.text = text
        if isBad {
            alert.circle.backgroundColor = .red
            alert.circle.isHidden = false
        } else {
            alert.circle.backgroundColor = .systemGreen
            alert.circle.isHidden = false
        }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let window = windowScene.windows.first {
                let backView = UIView()
                backView.translatesAutoresizingMaskIntoConstraints = false
                backView.backgroundColor = .systemGray5
                backView.alpha = 0.0
                alert.callbackClosure = { [weak backView] in
                    UIView.animate(withDuration: 0.2, animations: { [weak backView] in
                        backView?.alpha = 0.0
                    }, completion: { [weak backView] _ in
                        backView?.removeFromSuperview()
                    })
                }
                window.addSubview(alert)
                window.addSubview(backView)
                NSLayoutConstraint.activate([
                    backView.topAnchor.constraint(equalTo: window.topAnchor),
                    backView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                    backView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                    backView.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
                    
                    alert.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
                    alert.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
                    alert.widthAnchor.constraint(equalTo: window.widthAnchor),
                    alert.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                    alert.trailingAnchor.constraint(equalTo: window.trailingAnchor)
                ])
                UIView.animate(withDuration: 0.5, animations: { [weak alert, weak backView] in
                    alert?.alpha = 1
                    backView?.alpha = 1
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak alert, weak backView] in
                    UIView.animate(withDuration: 0.5, animations: { [weak alert, weak backView] in
                        alert?.alpha = 1
                        backView?.alpha = 1
                    }, completion: { [weak alert, weak backView] _ in
                        UIView.animate(withDuration: 0.5, delay: 7, animations: {
                            alert?.alpha = 0
                            backView?.alpha = 0
                        }, completion: { [weak alert, weak backView] _ in
                            alert?.removeFromSuperview()
                            backView?.removeFromSuperview()
                        })
                    })
                }
            }
        }
    }
    
    static func showAction(parent: UIViewController, message: String, addAlerts: [UIAlertAction]) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
        for action in addAlerts {
            alert.addAction(action)
        }
        DispatchQueue.main.async {
            parent.present(alert, animated: true)
        }
    }
}

extension Alert: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
}
