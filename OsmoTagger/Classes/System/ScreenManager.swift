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
    // true - dismiss SelectObjectVC; false - dismiss any vc
    var dismissClosure: ((Bool) -> Void)?
    
    let childWidth: CGFloat = 320
    
    // MARK: CHANGESET
    func openChangeset(parent: UIViewController) {
        if let viewControllers = navController?.viewControllers {
            // navController != nil
            if viewControllers[0] is SavedNodesViewController {
                if viewControllers.count == 1 {
                    return
                } else {
                    navController?.setViewControllers([viewControllers[0]], animated: true)
                }
            } else {
                // dismiss and open new navController
                navController?.dismiss(animated: true, completion: { [weak self, weak parent] in
                    guard let self = self,
                          let parent = parent else { return }
                    self.goToSAvedNodesVC(parent: parent)
                })
            }
        } else {
            // navController = nil, open new navigation controller
            goToSAvedNodesVC(parent: parent)
        }
    }
    
    private func goToSAvedNodesVC(parent: UIViewController) {
        let savedNodesVC = SavedNodesViewController()
        navController = SheetNavigationController(rootViewController: savedNodesVC)
        navController?.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.dismissClosure?(false)
            self.navController = nil
        }
        if navController != nil {
            moveUpClosure?()
            parent.present(navController!, animated: true)
        }
    }
    
    // MARK: SETTINGS
    func openSettings(parent: UIViewController) {
        if navController != nil {
            navController?.dismiss(animated: true) { [weak self, weak parent] in
                guard let self = self,
                      let parent = parent else { return }
                self.goToSettingsVC(parent: parent)
            }
        } else {
            goToSettingsVC(parent: parent)
        }
    }
    
    private func goToSettingsVC(parent: UIViewController) {
        let vc = MainViewController()
        navController = SheetNavigationController(rootViewController: vc)
        guard let sheetVC = navController?.sheetPresentationController else { return }
        // open the settings in full-screen mode
        sheetVC.detents = [.large()]
        navController?.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.navController = nil
        }
        if navController != nil {
            parent.present(navController!, animated: true)
        }
    }
    
    // MARK: SELECT OBJECT VC
    func openObjects(parent: UIViewController, objects: [OSMAnyObject]) {
        if let viewControllers = navController?.viewControllers {
            // navController != nil
            if let selectVC = viewControllers[0] as? SelectObjectViewController {
                selectVC.objects = objects
                selectVC.fillData()
                if viewControllers.count == 1 {
                    selectVC.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                } else {
                    navController?.setViewControllers([viewControllers[0]], animated: true, completion: {
                        selectVC.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                    })
                }
            } else {
                navController?.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else { return }
                    self.goToSelectVC(parent: parent, objects: objects)
                })
            }
        } else {
            // navController = nil, open new
            goToSelectVC(parent: parent, objects: objects)
        }
    }
    
    private func goToSelectVC(parent: UIViewController, objects: [OSMAnyObject]) {
        let selectVC = SelectObjectViewController(objects: objects)
        navController = SheetNavigationController(rootViewController: selectVC)
        navController?.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.dismissClosure?(true)
            self.navController = nil
        }
        if navController != nil {
            moveUpClosure?()
            parent.present(navController!, animated: true, completion: nil)
        }
    }
    
    // MARK: EDIT OBJECT VC
    func openObject(parent: UIViewController, object: OSMAnyObject) {
        if let viewControllers = navController?.viewControllers {
            // navController != nil
            if let selectVC = viewControllers[0] as? SelectObjectViewController {
                // selectVC -------------------------------
                if checkObjectInSelectVC(id: object.id, objects: selectVC.objects) {
                    if viewControllers.count > 1 {
                        editVCUpdateObject(viewControllers: viewControllers, newObject: object)
                    } else {
                        let editVC = EditObjectViewController(object: object)
                        navController?.pushViewController(editVC, animated: true)
                    }
                } else {
                    navController?.dismiss(animated: true, completion: { [weak self] in
                        guard let self = self else { return }
                        self.goToPropertiesVC(parent: parent, object: object)
                    })
                }
                // selectVC -------------------------------
            } else if viewControllers[0] is SavedNodesViewController {
                //  savedVC -------------------------------
                var savedObjects: [OSMAnyObject] = []
                for (_, object) in AppSettings.settings.savedObjects {
                    savedObjects.append(object)
                }
                for (_, object) in AppSettings.settings.deletedObjects {
                    savedObjects.append(object)
                }
                if checkObjectInSelectVC(id: object.id, objects: savedObjects) {
                    if viewControllers.count > 1 {
                        editVCUpdateObject(viewControllers: viewControllers, newObject: object)
                    } else {
                        let editVC = EditObjectViewController(object: object)
                        navController?.pushViewController(editVC, animated: true)
                    }
                } else {
                    navController?.dismiss(animated: true, completion: { [weak self] in
                        guard let self = self else { return }
                        self.goToPropertiesVC(parent: parent, object: object)
                    })
                }
                // savedVC -------------------------------
            } else if viewControllers[0] is EditObjectViewController {
                editVCUpdateObject(viewControllers: viewControllers, newObject: object)
            } else {
                navController?.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else { return }
                    self.goToPropertiesVC(parent: parent, object: object)
                })
            }
        } else {
            // navController = nil, open new
            goToPropertiesVC(parent: parent, object: object)
        }
    }
    
    private func goToPropertiesVC(parent: UIViewController, object: OSMAnyObject) {
        let editVC = EditObjectViewController(object: object)
        navController = SheetNavigationController(rootViewController: editVC)
        // When the user closes the tag editing controller, the backlight of the tapped object is removed.
        navController?.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.dismissClosure?(false)
            self.navController = nil
        }
        if navController != nil {
            moveUpClosure?()
            parent.present(navController!, animated: true, completion: nil)
        }
    }
    
    private func editVCUpdateObject(viewControllers: [UIViewController], newObject: OSMAnyObject) {
        for controller in viewControllers {
            if let infoVC = controller as? InfoObjectViewController {
                infoVC.object = newObject
                infoVC.fillData()
                infoVC.tableView.reloadData()
            }
        }
        for controller in viewControllers {
            if let editVC = controller as? EditObjectViewController {
                editVC.updateViewController(newObject: newObject)
                return
            }
        }
    }
    
    private func checkObjectInSelectVC(id: Int, objects: [OSMAnyObject]) -> Bool {
        for object in objects {
            if object.id == id {
                return true
            }
        }
        return false
    }
    
    func slideViewController(parent: UIViewController) {
        let vc = MainViewController()
        let navVC = SheetNavigationController(rootViewController: vc)
        let childAnchor = NSLayoutConstraint(item: navVC.view, attribute: .trailing, relatedBy: .equal, toItem: parent.view, attribute: .trailing, multiplier: 1, constant: childWidth)
        navVC.view.translatesAutoresizingMaskIntoConstraints = false
        navVC.dismissClosure = { [weak navVC, weak self, weak childAnchor, weak parent] in
            UIView.animate(withDuration: 0.2, animations: { [weak self, weak childAnchor, weak parent] in
                guard let self = self,
                      let childAnchor = childAnchor,
                      let parent = parent else { return }
                childAnchor.constant = self.childWidth
                self.moveRightClosure?()
                parent.view.layoutIfNeeded()
            }, completion: { [weak navVC] _ in
                navVC?.willMove(toParent: nil)
                navVC?.view.removeFromSuperview()
                navVC?.removeFromParent()
            })
        }
        parent.addChild(navVC)
        parent.view.addSubview(navVC.view)
        navVC.didMove(toParent: parent)
        NSLayoutConstraint.activate([
            navVC.view.topAnchor.constraint(equalTo: parent.view.topAnchor),
            childAnchor,
            navVC.view.widthAnchor.constraint(equalToConstant: childWidth),
            navVC.view.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor)
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
    
