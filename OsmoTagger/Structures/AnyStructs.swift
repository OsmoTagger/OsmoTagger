//
//  AnyStructs.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
//

import Foundation

//  Structures for EditObjectVC
struct EditSectionData {
    let name: String
    var items: [ItemElements]
}

//  Structures for Settings controllers
struct SettingsTableData {
    let name: String?
    let items: [SettingsCellData]
}

struct SettingsCellData {
    let icon: String
    let text: String
    let link: String
}

struct CategoryTableData {
    var type: CategoryCellType
    var icon: String?
    var text: String
    var path: ItemPath?
}

// Use on InfoVC
struct InfoCellData {
    let icon: String?
    let text: String
}
