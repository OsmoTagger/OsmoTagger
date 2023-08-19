//
//  NavigationControllers.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
//

import Foundation
import UIKit

//  Custom UINavigationController. It opens controllers for displaying saved objects, selecting an object in the case of tapping on several objects, and a tag editing controller.
class SheetNavigationController: UINavigationController {
    var dismissClosure: EmptyBlock?
    
    override func viewDidDisappear(_: Bool) {
        guard let closure = dismissClosure else { return }
        closure()
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        if let sheetPresentationController = self.presentationController as? UISheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
            sheetPresentationController.largestUndimmedDetentIdentifier = .medium
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool, completion: EmptyBlock?) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        setViewControllers(viewControllers, animated: animated)
        CATransaction.commit()
    }
}

//  UINavigationController for navigating presets
class CategoryNavigationController: UINavigationController {
    var callbackClosure: (([String: String]) -> Void)?
    var objectProperties: [String: String] = [:]
    
    override func viewDidDisappear(_: Bool) {
        guard let clouser = callbackClosure else { return }
        clouser(objectProperties)
    }
}
