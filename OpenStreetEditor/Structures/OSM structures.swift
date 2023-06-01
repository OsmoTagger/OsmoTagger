// структура xml файла для создания changeSet'а и для чтения входящего xml с данными немного разная

import Foundation
import GLMap
import XMLCoder

enum OsmClientErrors: Error {
    // object limit exceeded in request
    case objectLimit
}

// MARK: changeSet structures

struct osmChange: Decodable, Encodable, DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.version:
            return .attribute
        case CodingKeys.generator:
            return .attribute
        default:
            return .element
        }
    }

    let version: String
    let generator: String
    var modify: Modify
    var create: Create
    var delete: Delete
    enum CodingKeys: String, CodingKey {
        case version
        case generator
        case modify
        case create
        case delete
    }
}

struct Modify: Decodable, Encodable {
    var node: [Node]
    var way: [Way]
}

struct Create: Codable {
    var node: [Node]
    var way: [Way]
}

struct Delete: Codable {
    var node: [Node]
    var way: [Way]
}

// MARK: OSM DATA STRUCTURES

struct Node: Decodable, Encodable, DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.id:
            return .attribute
        case CodingKeys.version:
            return .attribute
        case CodingKeys.changeset:
            return .attribute
        case CodingKeys.lat:
            return .attribute
        case CodingKeys.lon:
            return .attribute
        default:
            return .element
        }
    }
    
    var id: Int
    var version: Int
    var changeset: Int
    var lat: Double
    var lon: Double
    var tag: [Tag]
    enum CodingKeys: String, CodingKey {
        case id
        case version
        case changeset
        case lat
        case lon
        case tag
    }
}

struct Tag: Codable, Equatable, DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.k:
            return .attribute
        case CodingKeys.v:
            return .attribute
        default:
            return .element
        }
    }

    var k: String
    var v: String
    let value: String
    enum CodingKeys: String, CodingKey {
        case k
        case v
        case value = ""
    }
}

struct Way: Codable, DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.id:
            return .attribute
        case CodingKeys.version:
            return .attribute
        case CodingKeys.changeset:
            return .attribute
        default:
            return .element
        }
    }

    let id: Int
    let version: Int
    var changeset: Int
    var tag: [Tag]
    var nd: [ND]
    enum CodingKeys: String, CodingKey {
        case id
        case version
        case changeset
        case nd
        case tag
    }
}

struct ND: Codable, DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.ref:
            return .attribute
        default:
            return .element
        }
    }

    let ref: Int
    enum CodingKeys: String, CodingKey {
        case ref
    }
}

enum OSMObjectType: String, Comparable, Codable {
    static func < (lhs: OSMObjectType, rhs: OSMObjectType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case node
    case way
    case closedway
    case multipolygon
}

//  A universal structure that stores all the data for conversion to Node and Way. The entire application works with it, and only before sending data to the server is encoded into the desired object, depending on the type
struct OSMAnyObject: Codable {
    var type: OSMObjectType
    let id: Int
    var version: Int
    var changeset: Int
    let lat: Double?
    let lon: Double?
    var tag: [Tag]
    var oldTags: [String: String]
    var nd: [ND]
    var nodes: [Int: Node]
    
    init(type: OSMObjectType, id: Int, version: Int, changeset: Int, lat: Double?, lon: Double?, tag: [Tag], nd: [ND], nodes: [Int: Node]) {
        self.type = type
        self.id = id
        self.version = version
        self.changeset = changeset
        self.lat = lat
        self.lon = lon
        self.tag = tag
        self.nd = nd
        self.nodes = nodes
        oldTags = [:]
        for tg in tag {
            oldTags[tg.k] = tg.v
        }
    }
    
    func getWay() -> Way {
        let way = Way(id: id, version: version, changeset: changeset, tag: tag, nd: nd)
        return way
    }
    
    func getNode() -> Node? {
        guard let lat = lat,
              let lon = lon else { return nil }
        let node = Node(id: id, version: version, changeset: changeset, lat: lat, lon: lon, tag: tag)
        return node
    }
    
    func getVectorObject() -> GLMapVectorObject {
        var vector = GLMapVectorObject()
        switch type {
        case .node:
            guard let lat = lat,
                  let lon = lon else { return vector }
            let point = GLMapPoint(lat: lat, lon: lon)
            vector = GLMapVectorObject(point: point)
            return vector
        case .way, .closedway:
            let pointArray = GLMapPointArray()
            for id in nd {
                guard let node = nodes[id.ref] else { continue }
                let point = GLMapPoint(lat: node.lat, lon: node.lon)
                pointArray.add(point)
            }
            vector = GLMapVectorObject(line: pointArray)
            return vector
        case .multipolygon:
            return vector
        }
    }
}

// MARK: OSM xml read structures

struct osm: Decodable, Encodable {
    var node: [Node]
    var way: [Way]
}

struct AuthSuccess: Decodable {
    let access_token: String
    let token_type: String
    let scope: String
    let created_at: Int
}

struct OSMUserInfo: Codable {
    let user: OSMUser
}

struct OSMUser: Codable {
    let id: Int
    let display_name: String
    let account_created: String
}
