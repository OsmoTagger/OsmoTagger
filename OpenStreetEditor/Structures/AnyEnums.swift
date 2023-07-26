//
//  Enums.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
//

import Foundation

//  Structures for the preset navigation controller
enum CategoryCellType {
    case category
    case group
    case item(tags: [String: String])
}

//  Structures for ItemVC
enum ItemCellType {
    case key
    case text
    case combo
    case check
    case label
    case link
    case space
}
