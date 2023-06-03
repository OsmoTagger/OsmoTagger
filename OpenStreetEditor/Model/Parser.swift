//
//  Parser.swift
//  josm parse
//
//  Created by Arkadiy on 20.03.2023.
//

import Foundation
import XMLCoder

//  A class for parsing a preset file.
class Parser {
    //  The method parses the "skeleton" of presets to compose the structure.
    func getSourceJosmPresets() -> Presets? {
        guard let path = Bundle.main.url(forResource: "defaultPresets", withExtension: "xml") else { return nil }

        do {
            let data = try Data(contentsOf: path)
            let preset = try XMLDecoder().decode(Presets.self, from: data)
            return preset
        } catch {
            print(error)
            return nil
        }
    }
    
    //  The method parses the "chunks" of presets (a set of tags that are repeated in the file).
    func fillChunks() {
        guard let path = Bundle.main.url(forResource: "defaultPresets", withExtension: "xml") else { return }
        do {
            let data = try Data(contentsOf: path)
            let parser = XMLParser(data: data)
            let delegate = ChunkElementsParser()
            parser.delegate = delegate
            parser.parse()
        } catch {
            print(error)
        }
    }
    
    //  the method fills the preset with tags (elements).
    func fillPresetForLine(preset: Presets) throws -> Presets {
        var newPreset = preset
        guard let path = Bundle.main.url(forResource: "defaultPresets", withExtension: "xml") else { fatalError() }
        do {
            let data = try Data(contentsOf: path)
            let parser = XMLParser(data: data)
            let delegate = PresetElementsParser(emptyPreset: preset)
            parser.delegate = delegate
            parser.parse()
            newPreset = delegate.preset
            return newPreset
        } catch {
            throw error
        }
    }
    
    func fillPresetElements() {
        guard let preset = getSourceJosmPresets() else { return }
        guard let path = Bundle.main.url(forResource: "defaultPresets", withExtension: "xml") else { return }
        do {
            let data = try Data(contentsOf: path)
            let parser = XMLParser(data: data)
            let delegate = PresetElementsParser(emptyPreset: preset)
            delegate.preset = preset
            parser.delegate = delegate
            parser.parse()
            AppSettings.settings.categories = delegate.preset.category
        } catch {
            print(error)
        }
        for category in AppSettings.settings.categories {
            for item in category.item {
                var dict: [String: String] = [:]
                for elem in item.elements {
                    switch elem {
                    case let .key(key, value):
                        dict[key] = value
                    default:
                        continue
                    }
                }
                if dict.isEmpty == false {
                    AppSettings.settings.itemPathes[dict] = ItemPath(category: category.name, group: nil, item: item.name)
                }
            }
            for group in category.group {
                for item in group.item {
                    var dict: [String: String] = [:]
                    for elem in item.elements {
                        switch elem {
                        case let .key(key, value):
                            dict[key] = value
                        default:
                            continue
                        }
                    }
                    if dict.isEmpty == false {
                        AppSettings.settings.itemPathes[dict] = ItemPath(category: category.name, group: group.name, item: item.name)
                    }
                }
            }
        }
//      the frequently used preset Building and Entrance do not have key=value pairs, and therefore it is not pulled up to objects. We enter it manually by copying the data from the xml file
        let values = ["allotment_house", "bakehouse", "barn", "basilica", "boathouse", "bunker", "cabin", "carport", "cathedral", "chapel", "church", "college", "commercial", "construction", "cowshed", "digester", "farm_auxiliary", "fire_station", "garage", "garages", "gasometer", "gatehouse", "grandstand", "greenhouse", "hangar", "hospital", "industrial", "kindergarten", "kiosk", "manufacture", "monastery", "mosque", "office", "pavilion", "parking", "public", "retail", "riding_hall", "roof", "ruins", "school", "service", "shed", "silo", "sports_centre", "sports_hall", "stable", "storage_tank", "sty", "supermarket", "synagogue", "temple", "tent", "toilets", "train_station", "transformer_tower", "transportation", "university", "warehouse", "yes"]
        let buildingPath = ItemPath(category: "Man Made", group: "Man Made", item: "Building")
        for value in values {
            let dict = ["building": value]
            AppSettings.settings.itemPathes[dict] = buildingPath
        }
        let entranceValues = ["main", "service", "shop", "exit", "emergency", "staircase", "home", "garage", "yes"]
        let entrancePath = ItemPath(category: "Man Made", group: "Man Made", item: "Entrance")
        for value in entranceValues {
            let dict = ["entrance": value]
            AppSettings.settings.itemPathes[dict] = entrancePath
        }
    }
}

class OSMXmlParser: NSObject {
    var objects: [Int: Any] = [:]
    var curNode: Node?
    var curWay: Way?
    var curRelation: Relation?
}

extension OSMXmlParser: XMLParserDelegate {
    func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "node" {
            guard let idString = attributeDict["id"],
                  let versionString = attributeDict["version"],
                  let changesetString = attributeDict["changeset"],
                  let latString = attributeDict["lat"],
                  let lonString = attributeDict["lon"],
                  let id = Int(idString),
                  let version = Int(versionString),
                  let changeset = Int(changesetString),
                  let lat = Double(latString),
                  let lon = Double(lonString) else { return }
            curNode = Node(id: id, version: version, changeset: changeset, lat: lat, lon: lon, tag: [])
        }
        if elementName == "way" {
            guard let idString = attributeDict["id"],
                  let versionString = attributeDict["version"],
                  let changesetString = attributeDict["changeset"],
                  let id = Int(idString),
                  let version = Int(versionString),
                  let changeset = Int(changesetString) else { return }
            curWay = Way(id: id, version: version, changeset: changeset, tag: [], nd: [])
        }
        if elementName == "relation" {
            guard let idString = attributeDict["id"],
                  let versionString = attributeDict["version"],
                  let changesetString = attributeDict["changeset"],
                  let id = Int(idString),
                  let version = Int(versionString),
                  let changeset = Int(changesetString) else { return }
            curRelation = Relation(id: id, version: version, changeset: changeset, member: [], tag: [])
        }
        if elementName == "member" {
            guard let type = attributeDict["type"],
                  let refString = attributeDict["ref"],
                  let role = attributeDict["role"],
                  let ref = Int(refString) else { return }
            let member = Member(type: type, ref: ref, role: role)
            curRelation?.member.append(member)
        }
        if elementName == "tag" {
            guard let key = attributeDict["k"],
                  let value = attributeDict["v"] else { return }
            let tag = Tag(k: key, v: value, value: "")
            if curNode != nil && curWay == nil && curRelation == nil {
                // fill node
                curNode?.tag.append(tag)
            } else if curNode == nil && curWay != nil && curRelation == nil {
                // fill way
                curWay?.tag.append(tag)
            } else if curNode == nil && curWay == nil && curRelation != nil {
                curRelation?.tag.append(tag)
            }
        }
        if elementName == "nd" {
            guard let refString = attributeDict["ref"],
                  let ref = Int(refString) else { return }
            let nd = ND(ref: ref)
            curWay?.nd.append(nd)
        }
    }
    
    func parser(_: XMLParser, didEndElement: String, namespaceURI _: String?, qualifiedName _: String?) {
        if didEndElement == "node" {
            guard let node = curNode else { return }
            objects[node.id] = node
            curNode = nil
        }
        if didEndElement == "way" {
            guard let way = curWay else { return }
            objects[way.id] = way
            curWay = nil
        }
        if didEndElement == "relation" {
            guard let relation = curRelation else { return }
            objects[relation.id] = relation
            curRelation = nil
        }
    }
}

class PresetElementsParser: NSObject {
    var preset: Presets
    var item: Item = .init(name: "", icon: nil, type: [], elements: [])
    
    var lastCategory: String = ""
    var categoryOpen = false
    var lastGroup: String?
    var groupOpen = false
    var itemName: String = ""
    var itemOpen = false
    
    var result: [ItemElements] = []
    
    var comboOpen = false
    var tmpCombo: Combo?

    init(emptyPreset: Presets) {
        preset = emptyPreset
        super.init()
    }
}

extension PresetElementsParser: XMLParserDelegate {
    func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "category" {
            guard let name = attributeDict["name"] else { return }
            lastCategory = name
            categoryOpen = true
        }
        if elementName == "group" {
            guard let name = attributeDict["name"] else { return }
            lastGroup = name
            groupOpen = true
        }
        if elementName == "item" {
            guard let name = attributeDict["name"],
                  let typeString = attributeDict["type"] else { return }
            let type = typeString.split(separator: ",").compactMap { OSMObjectType(rawValue: String($0)) }
            item = Item(name: name, icon: attributeDict["icon"]?.replacingOccurrences(of: "/", with: "+"), type: type, elements: [])
            itemName = name
            itemOpen = true
        }
        if itemOpen == true {
            switch elementName {
            case "key":
                guard let key = attributeDict["key"] else { return }
                guard let value = attributeDict["value"] else { return }
                let elem = ItemElements.key(key: key, value: value)
                result.append(elem)
            case "link":
                guard let link = attributeDict["wiki"] else { return }
                let elem = ItemElements.link(wiki: link)
                result.append(elem)
            case "text":
                guard let text = attributeDict["text"] else { return }
                guard let key = attributeDict["key"] else { return }
                let elem = ItemElements.text(text: text, key: key)
                result.append(elem)
            case "combo":
                if let string = attributeDict["values"] {
                    let values = string.components(separatedBy: ",")
                    guard let key = attributeDict["key"] else { return }
                    let elem = ItemElements.combo(key: key, values: values, defaultValue: attributeDict["default"])
                    result.append(elem)
                } else {
                    comboOpen = true
                    guard let key = attributeDict["key"] else { return }
                    tmpCombo = Combo(key: key, defaultValue: attributeDict["default"], values: [], list_entry: [])
                }
            case "multiselect":
                guard let key = attributeDict["key"],
                      let valuesString = attributeDict["values"],
                      let text = attributeDict["text"] else { return }
                let values = valuesString.components(separatedBy: ";")
                let elem = ItemElements.multiselect(key: key, values: values, text: text)
                result.append(elem)
            case "list_entry":
                guard let value = attributeDict["value"] else { return }
                tmpCombo?.values.append(value)
            case "check":
                guard let key = attributeDict["key"] else { return }
                let elem = ItemElements.check(key: key, text: attributeDict["text"], valueOn: attributeDict["value_on"])
                result.append(elem)
            case "reference":
                guard let ref = attributeDict["ref"] else { return }
                let elem = ItemElements.reference(ref: ref)
                result.append(elem)
            case "preset_link":
                guard let link = attributeDict["preset_name"] else { return }
                let elem = ItemElements.presetLink(presetName: link)
                result.append(elem)
            case "label":
                guard let text = attributeDict["text"] else { return }
                let elem = ItemElements.label(text: text)
                result.append(elem)
            default:
                return
            }
        }
    }
    
    func parser(_: XMLParser, didEndElement: String, namespaceURI _: String?, qualifiedName _: String?) {
        if didEndElement == "item" {
            itemOpen = false
            item.elements = result
            result = []
            preset.updateItem(categoryName: lastCategory, groupName: lastGroup, itemName: itemName, newItem: item)
        }
        if didEndElement == "group" {
            lastGroup = nil
            groupOpen = false
        }
        if didEndElement == "category" {
            lastCategory = ""
            categoryOpen = false
        }
        if didEndElement == "combo" && comboOpen == true {
            comboOpen = false
            if tmpCombo != nil {
                let elem = ItemElements.combo(key: tmpCombo!.key, values: tmpCombo!.values, defaultValue: tmpCombo?.defaultValue)
                result.append(elem)
                tmpCombo = nil
            } else {
                return
            }
        }
    }
}

class ChunkElementsParser: NSObject {
    var chunkOpen = false
    var lastID = ""
    var result: [ItemElements] = []
    
    var comboOpen = false
    var tmpCombo: Combo?
}

extension ChunkElementsParser: XMLParserDelegate {
    func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "chunk" {
            chunkOpen = true
            guard let id = attributeDict["id"] else { return }
            AppSettings.settings.chunks[id] = []
            lastID = id
        }
        if chunkOpen {
            switch elementName {
            case "key":
                guard let key = attributeDict["key"] else { return }
                guard let value = attributeDict["value"] else { return }
                let elem = ItemElements.key(key: key, value: value)
                result.append(elem)
            case "combo":
                if let string = attributeDict["values"] {
                    let values = string.components(separatedBy: ",")
                    guard let key = attributeDict["key"] else { return }
                    let elem = ItemElements.combo(key: key, values: values, defaultValue: attributeDict["default"])
                    result.append(elem)
                } else {
                    comboOpen = true
                    guard let key = attributeDict["key"] else { return }
                    tmpCombo = Combo(key: key, defaultValue: attributeDict["default"], values: [], list_entry: [])
                }
            case "multiselect":
                guard let key = attributeDict["key"],
                      let valuesString = attributeDict["values"],
                      let text = attributeDict["text"] else { return }
                let values = valuesString.components(separatedBy: ";")
                let elem = ItemElements.multiselect(key: key, values: values, text: text)
                result.append(elem)
            case "list_entry":
                guard let value = attributeDict["value"] else { return }
                tmpCombo?.values.append(value)
            case "check":
                guard let key = attributeDict["key"] else { return }
                guard let text = attributeDict["text"] else { return }
                let elem = ItemElements.check(key: key, text: text, valueOn: attributeDict["value_on"])
                result.append(elem)
            case "label":
                guard let text = attributeDict["text"] else { return }
                let elem = ItemElements.label(text: text)
                result.append(elem)
            case "text":
                guard let text = attributeDict["text"] else { return }
                guard let key = attributeDict["key"] else { return }
                let elem = ItemElements.text(text: text, key: key)
                result.append(elem)
            case "preset_link":
                guard let link = attributeDict["preset_name"] else { return }
                let elem = ItemElements.presetLink(presetName: link)
                result.append(elem)
            case "reference":
                guard let ref = attributeDict["ref"] else { return }
                let elem = ItemElements.reference(ref: ref)
                result.append(elem)
            default:
                return
            }
        } else {
            return
        }
    }
    
    func parser(_: XMLParser, didEndElement: String, namespaceURI _: String?, qualifiedName _: String?) {
        if didEndElement == "chunk" {
            chunkOpen = false
            AppSettings.settings.chunks[lastID] = result
            result = []
        }
        if didEndElement == "combo" && comboOpen == true {
            comboOpen = false
            if tmpCombo != nil {
                let elem = ItemElements.combo(key: tmpCombo!.key, values: tmpCombo!.values, defaultValue: tmpCombo?.defaultValue)
                result.append(elem)
                tmpCombo = nil
            } else {
                return
            }
        }
    }
}
