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
    
    //  The structure of Josm presets looks like this: category - group or preset - preset (Item).
    //  The method is used to get a preset from the category name, the group, and the preset itself.
    func getItemFromPath(path: ItemPath) -> Item? {
        for category in AppSettings.settings.categories where category.name == path.category {
            if path.group == nil {
                let items = category.item
                for item in items where item.name == path.item {
                    return item
                }
            } else {
                for group in category.group where group.name == path.group {
                    let items = group.item
                    for item in items where item.name == path.item {
                        return item
                    }
                }
            }
        }
        return nil
    }
    
    //  The method is used to get a preset if only its name is known. Tests have found that in places where this method is used, the names of presets are always unique
    func getItemFromName(name: String) -> Item? {
        for category in AppSettings.settings.categories {
            for item in category.item {
                if item.name == name {
                    return item
                }
            }
            for group in category.group {
                for item in group.item {
                    if item.name == name {
                        return item
                    }
                }
            }
        }
        return nil
    }
    
    //  The method defines an array of presets that fit an OSM object with a set of tags. If no suitable presets are found, the array is empty.
    func getItemsFromTags(properties: [String: String]) -> [ItemPath] {
        var pathes: [ItemPath] = []
        if let path = AppSettings.settings.itemPathes[properties] {
            pathes.append(path)
            return pathes
        } else {
            for (keysDict, path) in AppSettings.settings.itemPathes {
                let coincidences = properties.filter { keysDict[$0.key] == $0.value }
                if coincidences.count == keysDict.count {
                    pathes.append(path)
                }
            }
        }
        return pathes
    }
    
    //  To be able to edit tags and points and ways OSM, an OSMAnyObject object is created, which includes all the data that allows you to get the original point object or path from it again at the right time to send changes to the server.
    //  The method converts OSMAnyObject to Node or Way, depending on the type "type" that is specified during its initialization.
    func convertOSMToObject(osmObject: Any) -> OSMAnyObject? {
        if let object = osmObject as? Node {
            let point = OSMAnyObject(type: .node, id: object.id, version: object.version, changeset: object.changeset, lat: object.lat, lon: object.lon, tag: object.tag, nd: [], nodes: [:])
            return point
        } else if let object = osmObject as? Way {
            var nodes: [Int: Node] = [:]
            for id in object.nd {
                guard let node = AppSettings.settings.inputObjects[id.ref] as? Node else { continue }
                nodes[node.id] = node
            }
            if object.nd[0].ref == object.nd.last?.ref {
                let closedWay = OSMAnyObject(type: .closedway, id: object.id, version: object.version, changeset: object.changeset, lat: nil, lon: nil, tag: object.tag, nd: object.nd, nodes: nodes)
                return closedWay
            } else {
                let way = OSMAnyObject(type: .way, id: object.id, version: object.version, changeset: object.changeset, lat: nil, lon: nil, tag: object.tag, nd: object.nd, nodes: nodes)
                return way
            }
        } else {
            return nil
        }
    }
}
