//
//  Presets.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 25.08.2023.
//

import Foundation

// Class for searching presets.
class PresetClient {
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
}
