//
//  OverpassParser.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 03.10.2023.
//

import Foundation
import GLMap

class OverpassParser: NSObject {
    let objects = GLMapVectorObjectArray()
    var lastObject: GLMapVectorPoint?
    var lastID: String?
}

extension OverpassParser: XMLParserDelegate {
    func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        switch elementName {
        case "node":
            guard let latStr = attributeDict["lat"],
                  let lonStr = attributeDict["lon"],
                  let lat = Double(latStr),
                  let lon = Double(lonStr),
                  let idStr = attributeDict["id"] else { return }
            let glPoint = GLMapPoint(lat: lat, lon: lon)
            lastObject = GLMapVectorPoint(glPoint)
            lastObject?.setValue(idStr, forKey: "@id")
        case "way":
            lastID = attributeDict["id"]
        case "center":
            guard let latStr = attributeDict["lat"],
                  let lat = Double(latStr),
                  let lonStr = attributeDict["lon"],
                  let lon = Double(lonStr),
                  let lastID = lastID else { return }
            let glPoint = GLMapPoint(lat: lat, lon: lon)
            lastObject = GLMapVectorPoint(glPoint)
            lastObject?.setValue(lastID, forKey: "@id")
        case "tag":
            guard let key = attributeDict["k"],
                  let value = attributeDict["v"] else { return }
            lastObject?.setValue(key, forKey: value)
        default:
            return
        }
    }
    
    func parser(_: XMLParser, didEndElement: String, namespaceURI _: String?, qualifiedName _: String?) {
        switch didEndElement {
        case "node", "way":
            guard let lastObject = lastObject else { return }
            objects.add(lastObject)
            self.lastObject = nil
            lastID = nil
        default:
            return
        }
    }
}
