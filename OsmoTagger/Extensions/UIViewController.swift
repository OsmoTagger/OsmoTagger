//
//  UIViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 29.01.2023.
//

import Foundation
import UIKit

extension UIViewController {
    //  It is used to quickly get a loading indicator on any controller.
    func showIndicator() -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView()
        indicator.color = .red
        indicator.style = .large
        view.window?.addSubview(indicator)
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        return indicator
    }

    func removeIndicator(indicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            indicator.removeFromSuperview()
        }
    }

    //  Method for presenting UIAlertController on any ViewController.
    func showAction(message: String, addAlerts: [UIAlertAction]) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
            if addAlerts.isEmpty {
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
            } else {
                for action in addAlerts {
                    alert.addAction(action)
                }
            }
            self.present(alert, animated: true, completion: nil)
        }
    }
}
