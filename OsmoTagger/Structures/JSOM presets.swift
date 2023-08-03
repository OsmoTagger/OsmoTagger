//
//  VespucciPreset.swift
//  OSM editor
//
//  Created by Arkadiy on 05.03.2023.
//

import Foundation
import XMLCoder

//  Stores the path to the preset for a quick transition to it
struct ItemPath: Codable, Equatable {
    var category: String
    var group: String?
    var item: String
}

//  The whole preset. The updateItem method is called when parsing a file to fill presets with elements (tags)
struct Presets: Codable {
    var category: [Category]
    
    mutating func updateItem(categoryName: String, groupName: String?, itemName: String, newItem: Item) {
        if groupName == nil {
            for i in category.indices {
                if category[i].name == categoryName {
                    var cat = category.remove(at: i)
                    for j in cat.item.indices {
                        if cat.item[j].name == itemName {
                            cat.item.remove(at: j)
                            cat.item.insert(newItem, at: j)
                        }
                    }
                    category.insert(cat, at: i)
                }
            }
        } else {
            for i in category.indices {
                if category[i].name == categoryName {
                    var cat = category.remove(at: i)
                    for j in cat.group.indices {
                        if cat.group[j].name == groupName {
                            var gr = cat.group.remove(at: j)
                            for k in gr.item.indices {
                                if gr.item[k].name == itemName {
                                    gr.item.remove(at: k)
                                    gr.item.insert(newItem, at: k)
                                }
                            }
                            cat.group.insert(gr, at: j)
                        }
                    }
                    category.insert(cat, at: i)
                }
            }
        }
    }
}

struct Category: Codable, DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.name:
            return .attribute
        case CodingKeys.icon:
            return .attribute
        default:
            return .element
        }
    }

    let name: String
    let icon: String
    var group: [Group]
    var item: [Item]
    enum CodingKeys: String, CodingKey {
        case name
        case icon
        case group
        case item
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let iconString = try container.decode(String.self, forKey: .icon)
        icon = iconString.replacingOccurrences(of: "/", with: "+")
        group = try container.decode([Group].self, forKey: .group)
        item = try container.decode([Item].self, forKey: .item)
    }
}

struct Group: Codable, DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.name:
            return .attribute
        case CodingKeys.icon:
            return .attribute
        default:
            return .element
        }
    }

    let name: String
    let icon: String
    var item: [Item]
    enum CodingKeys: String, CodingKey {
        case name
        case icon
        case item
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let iconString = try container.decode(String.self, forKey: .icon)
        icon = iconString.replacingOccurrences(of: "/", with: "+")
        item = try container.decode([Item].self, forKey: .item)
    }
}

// File Elements defaultpresets.xml from Josm.
// Documentation - https://josm.openstreetmap.de/wiki/Ru%3ATaggingPresets#XML
enum ItemElements: Codable, Hashable {
    case key(key: String, value: String)
    case link(wiki: String)
    case text(text: String, key: String)
    case combo(key: String, values: [String], defaultValue: String?)
    case reference(ref: String)
    case check(key: String, text: String?, valueOn: String?)
    case presetLink(presetName: String)
    case multiselect(key: String, values: [String], text: String)
    case label(text: String)
}

//  Directly preset
struct Item: Codable, DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.name:
            return .attribute
        case CodingKeys.icon:
            return .attribute
        case CodingKeys.type:
            return .attribute
        default:
            return .element
        }
    }

    let name: String
    let icon: String?
    let type: [OSMObjectType]
    var elements: [ItemElements]
    var path: ItemPath? = nil
    enum CodingKeys: String, CodingKey {
        case name
        case icon
        case type
        case elements
        case path
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        do {
            icon = try container.decode(String.self, forKey: .icon)
        } catch {
            icon = nil
        }
        let typeString = try container.decode(String.self, forKey: .type)
        type = typeString.split(separator: ",").compactMap { OSMObjectType(rawValue: String($0)) }
        elements = []
    }

    init(name: String, icon: String?, type: [OSMObjectType], elements: [ItemElements]) {
        self.name = name
        self.icon = icon
        self.type = type
        self.elements = elements
    }
}

//  The Combo element that is used in the preset. Later, it is necessary to replace it with ItemElements.combo in parsing the file
struct Combo: Codable, DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.key:
            return .attribute
        case CodingKeys.values:
            return .attribute
        default:
            return .element
        }
    }

    let key: String
    let defaultValue: String?
    var values: [String]
    let list_entry: [ListEntry]
    enum CodingKeys: String, CodingKey {
        case key
        case defaultValue
        case values
        case list_entry
    }
}

struct ListEntry: Codable, DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.value:
            return .attribute
        case CodingKeys.icon:
            return .attribute
        default:
            return .element
        }
    }

    let value: String
    let icon: String?
    enum CodingKeys: String, CodingKey {
        case value
        case icon
    }
}
