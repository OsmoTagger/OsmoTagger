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
                let leadingSafeAreaView = UIView()
                leadingSafeAreaView.backgroundColor = .systemGray5
                leadingSafeAreaView.alpha = 0.0
                leadingSafeAreaView.translatesAutoresizingMaskIntoConstraints = false
                
                let topSafeAreaView = UIView()
                topSafeAreaView.translatesAutoresizingMaskIntoConstraints = false
                topSafeAreaView.backgroundColor = .systemGray5
                topSafeAreaView.alpha = 0.0
                
                alert.callbackClosure = { [weak topSafeAreaView, weak leadingSafeAreaView] in
                    UIView.animate(withDuration: 0.2, animations: { [weak topSafeAreaView, weak leadingSafeAreaView] in
                        topSafeAreaView?.alpha = 0.0
                        leadingSafeAreaView?.alpha = 0.0
                    }, completion: { [weak topSafeAreaView, weak leadingSafeAreaView] _ in
                        topSafeAreaView?.removeFromSuperview()
                        leadingSafeAreaView?.removeFromSuperview()
                    })
                }
                window.addSubview(topSafeAreaView)
                window.addSubview(leadingSafeAreaView)
                window.addSubview(alert)
                let alertTrailingAnchor: NSLayoutConstraint
                let alertHeightAnchor: NSLayoutConstraint
                let trailingTopSafeAreaViewAnchor: NSLayoutConstraint
                if isPad {
                    alertTrailingAnchor = NSLayoutConstraint(item: alert, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 400)
                    alertHeightAnchor = NSLayoutConstraint(item: alert, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
                    trailingTopSafeAreaViewAnchor = NSLayoutConstraint(item: topSafeAreaView, attribute: .trailing, relatedBy: .equal, toItem: alert, attribute: .trailing, multiplier: 1, constant: 0)
                } else {
                    alertTrailingAnchor = NSLayoutConstraint(item: alert, attribute: .trailing, relatedBy: .equal, toItem: window, attribute: .trailing, multiplier: 1, constant: 0)
                    alertHeightAnchor = NSLayoutConstraint(item: alert, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 40)
                    trailingTopSafeAreaViewAnchor = NSLayoutConstraint(item: topSafeAreaView, attribute: .trailing, relatedBy: .equal, toItem: window, attribute: .trailing, multiplier: 1, constant: 0)
                }
                NSLayoutConstraint.activate([
                    leadingSafeAreaView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                    leadingSafeAreaView.topAnchor.constraint(equalTo: window.topAnchor),
                    leadingSafeAreaView.trailingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.leadingAnchor),
                    leadingSafeAreaView.bottomAnchor.constraint(equalTo: alert.bottomAnchor),
                    
                    topSafeAreaView.topAnchor.constraint(equalTo: window.topAnchor),
                    topSafeAreaView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                    trailingTopSafeAreaViewAnchor,
                    topSafeAreaView.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
                    
                    alert.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
                    alert.leadingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.leadingAnchor),
                    alertTrailingAnchor, alertHeightAnchor,
                ])
                UIView.animate(withDuration: 0.5, animations: { [weak alert, weak topSafeAreaView, weak leadingSafeAreaView] in
                    alert?.alpha = 1
                    topSafeAreaView?.alpha = 1
                    leadingSafeAreaView?.alpha = 1
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak alert, weak topSafeAreaView, weak leadingSafeAreaView] in
                    UIView.animate(withDuration: 0.5, animations: { [weak alert, weak topSafeAreaView, weak leadingSafeAreaView] in
                        alert?.alpha = 0
                        topSafeAreaView?.alpha = 0
                        leadingSafeAreaView?.alpha = 0
                    }, completion: { [weak alert, weak topSafeAreaView, weak leadingSafeAreaView] _ in
                        alert?.removeFromSuperview()
                        topSafeAreaView?.removeFromSuperview()
                        leadingSafeAreaView?.removeFromSuperview()
                    })
                }
            }
        }
    }
    
    static func showAction(parent: UIViewController, message: String, addAlerts: [UIAlertAction]) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
        if addAlerts.isEmpty {
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
        } else {
            for action in addAlerts {
                alert.addAction(action)
            }
        }
        DispatchQueue.main.async {
            parent.present(alert, animated: true)
        }
    }
}

extension Alert: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool { return true }
}
