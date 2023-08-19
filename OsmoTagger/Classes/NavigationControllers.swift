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
