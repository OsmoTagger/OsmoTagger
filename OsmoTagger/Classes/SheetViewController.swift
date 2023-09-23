//
//  CloseButtonViewController.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 19.08.2023.
//

import Foundation
import UIKit

// SheetViewController is used within the SheetNavigationController stack. It tracks the screen orientation and adds a close button when necessary for proper functionality in landscape screen orientation
class SheetViewController: UIViewController {
    private var closeButton: UIBarButtonItem {
        let button = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(tapCloseButton))
        return button
    }

    var rightButtons: [UIBarButtonItem] = [] {
        didSet {
            rightButtons.insert(closeButton, at: 0)
            navigationItem.rightBarButtonItems = rightButtons
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        navigationItem.rightBarButtonItems = [closeButton]
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapCloseButton() {
        if isPad, let sheetNavVC = navigationController as? SheetNavigationController {
            sheetNavVC.dismissClosure?()
        } else {
            navigationController?.dismiss(animated: true)
        }
    }
}
