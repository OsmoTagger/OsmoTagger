//
//  LineTool settings.swift
//  LineTool
//
//  Created by Arkadiy on 20.04.2023.
//

import Foundation

class AppSettings: NSObject {
    static let settings = AppSettings()
    
//    MARK: PRESETS

    var chunks: [String: [ItemElements]] = [:]
    
    var categories: [Category] = []
    
    var itemPathes: [[String: String]: ItemPath] = [:]
}
