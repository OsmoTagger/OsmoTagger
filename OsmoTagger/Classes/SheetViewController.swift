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
    private let closebuttonTag = 25
    private var closeButton: UIBarButtonItem {
        let button = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(tapCloseButton))
        button.tag = closebuttonTag
        return button
    }
    
    var rightButtons: [UIBarButtonItem] = [] {
        didSet {
            navigationItem.rightBarButtonItems = rightButtons
            checkRightButtons()
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        checkRightButtons()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillTransition(to _: CGSize, with _: UIViewControllerTransitionCoordinator) {
        checkRightButtons()
    }
    
    private func checkRightButtons() {
        var items = navigationItem.rightBarButtonItems ?? []
        if isLandscape {
            if items.first?.tag != closebuttonTag {
                items.insert(closeButton, at: 0)
            }
        } else {
            if items.first?.tag == closebuttonTag {
                items.removeFirst()
            }
        }
        navigationItem.rightBarButtonItems = items
    }
    
    @objc private func tapCloseButton() {
        navigationController?.dismiss(animated: true)
    }
}
