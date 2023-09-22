//
//  ScreenManager.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 22.09.2023.
//

import Foundation

class ScreenManager {
    
    var navController: SheetNavigationController?
    
    func tapTestButton() {
        let vc = MainViewController()
        let navVC = SheetNavigationController(rootViewController: vc)
        let childAnchor = NSLayoutConstraint(item: navVC.view, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: childWidth)
        navVC.view.translatesAutoresizingMaskIntoConstraints = false
        navVC.dismissClosure = { [weak navVC, weak self, weak childAnchor] in
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                guard let self = self else { return }
                self.mapViewTrailingAnchor.constant = 0
                childAnchor?.constant = self.childWidth
                self.view.layoutIfNeeded()
            }, completion: { [weak navVC] _ in
                navVC?.willMove(toParent: nil)
                navVC?.view.removeFromSuperview()
                navVC?.removeFromParent()
            })
        }
        addChild(navVC)
        view.addSubview(navVC.view)
        navVC.didMove(toParent: self)
        NSLayoutConstraint.activate([
            navVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            childAnchor,
            navVC.view.widthAnchor.constraint(equalToConstant: childWidth),
            navVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: { [weak self, weak childAnchor] in
            guard let self = self else { return }
            childAnchor?.constant = 0
            self.mapViewTrailingAnchor.constant = -self.childWidth
            self.view.layoutIfNeeded()
        })
    }
    
}
