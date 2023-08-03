//
//  GLMapVectorObject.swift
//  OSM editor
//
//  Created by Arkadiy on 29.01.2023.
//

import Foundation
import GLMapCore

//  The loaded OSM data is displayed on the map as a GLMapVectorObject. The unique identifier of the object is the id.
//  The method gets an Int(id), which is stored in the "properties" of each GLMapVectorObject.
extension GLMapVectorObject {
    func getObjectID() -> Int? {
        guard let str = value(forKey: "@id")?.asString(),
              let double = Double(str) else { return nil }
        return Int(double)
    }
}

enum GLMapVectoObjectType {
    case simple
    case polygon(line: GLMapVectorLine)
}
