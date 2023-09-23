//
//  ScreenManager.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 22.09.2023.
//

import UIKit

class ScreenManager {
    var navController: SheetNavigationController?
    
    var moveUpClosure: EmptyBlock?
    var moveLeftClosure: EmptyBlock?
    var moveRightClosure: EmptyBlock?
    var moveDownClosure: EmptyBlock?
    var removeTappedObjectsClosure: EmptyBlock?
    
    let childWidth: CGFloat = 320
    
    // MARK: CHANGESET

    func openSavedNodesVC(parent: UIViewController) {
        let savedNodesVC = SavedNodesViewController()
        openViewController(parent: parent, newVC: savedNodesVC)
    }
    
    // MARK: SETTINGS

    func openSettings(parent: UIViewController) {
        let vc = MainViewController()
        openViewController(parent: parent, newVC: vc)
    }
    
    // MARK: SELECT OBJECT VC

    func openSelectObjectVC(parent: UIViewController, objects: [OSMAnyObject]) {
        let viewControllers: [UIViewController]
        if isPad {
            viewControllers = (parent.children.first as? UINavigationController)?.viewControllers ?? []
        } else {
            viewControllers = navController?.viewControllers ?? []
        }
        
        if viewControllers.count > 0,
           let selectVC = viewControllers[0] as? SelectObjectViewController
        {
            selectVC.objects = objects
            selectVC.fillData()
            if viewControllers.count == 1 {
                selectVC.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            } else {
                navController?.setViewControllers([viewControllers[0]], animated: true, completion: {
                    selectVC.tableView.reloadData()
                })
            }
        } else {
            let selectVC = SelectObjectViewController(objects: objects)
            selectVC.deinitClosure = { [weak self] in
                self?.removeTappedObjectsClosure?()
            }
            openViewController(parent: parent, newVC: selectVC)
        }
    }
    
    // MARK: EDIT OBJECT VC

    func editObject(parent: UIViewController, object: OSMAnyObject) {
        let viewControllers: [UIViewController]
        if isPad {
            viewControllers = (parent.children.first as? UINavigationController)?.viewControllers ?? []
        } else {
            viewControllers = navController?.viewControllers ?? []
        }
        if viewControllers.count > 0,
           let _ = viewControllers[0] as? EditObjectViewController
        {
            for controller in viewControllers {
                if let infoVC = controller as? InfoObjectViewController {
                    infoVC.object = object
                    infoVC.fillData()
                    infoVC.tableView.reloadData()
                }
            }
            for controller in viewControllers {
                if let editVC = controller as? EditObjectViewController {
                    editVC.updateViewController(newObject: object)
                }
            }
        } else {
            let editVC = EditObjectViewController(object: object)
            openViewController(parent: parent, newVC: editVC)
        }
    }
    
    // MARK: OPEN VC
    
    private func openViewController(parent: UIViewController, newVC: UIViewController) {
        if let navVC = navController {
            navVC.setViewControllers([newVC], animated: true)
        } else {
            navController = SheetNavigationController(rootViewController: newVC)
            if isPad {
                slideViewController(parent: parent)
            } else {
                presentViewController(parent: parent)
            }
        }
    }
    
    private func presentViewController(parent: UIViewController) {
        guard let navVC = navController else { return }
        navVC.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.moveDownClosure?()
            self.navController = nil
        }
        moveUpClosure?()
        parent.present(navVC, animated: true)
    }
    
    private func slideViewController(parent: UIViewController) {
        guard let navVC = navController else { return }
        let childAnchor = NSLayoutConstraint(item: navVC.view, attribute: .trailing, relatedBy: .equal, toItem: parent.view, attribute: .trailing, multiplier: 1, constant: childWidth)
        navVC.view.translatesAutoresizingMaskIntoConstraints = false
        navVC.tapCloseClosure = { [weak navVC, weak self, weak childAnchor, weak parent] in
            UIView.animate(withDuration: 0.2, animations: { [weak self, weak childAnchor, weak parent] in
                guard let self = self,
                      let childAnchor = childAnchor,
                      let parent = parent else { return }
                self.moveRightClosure?()
                childAnchor.constant = self.childWidth
                parent.view.layoutIfNeeded()
            }, completion: { [weak self, weak navVC] _ in
                navVC?.willMove(toParent: nil)
                navVC?.view.removeFromSuperview()
                navVC?.removeFromParent()
                self?.navController = nil
            })
        }
        parent.addChild(navVC)
        parent.view.addSubview(navVC.view)
        navVC.didMove(toParent: parent)
        NSLayoutConstraint.activate([
            navVC.view.topAnchor.constraint(equalTo: parent.view.topAnchor),
            childAnchor,
            navVC.view.widthAnchor.constraint(equalToConstant: childWidth),
            navVC.view.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor),
        ])
        parent.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: { [weak self, weak childAnchor] in
            guard let self = self else { return }
            self.moveLeftClosure?()
            childAnchor?.constant = 0
            parent.view.layoutIfNeeded()
        })
    }
}
    