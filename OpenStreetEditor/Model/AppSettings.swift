//
//  AppSettings.swift
//  OSM editor
//
//  Created by Arkadiy on 11.11.2022.
//

import GLMap
import UIKit

import XMLCoder

//  Singleton for storing app settings
final class AppSettings: NSObject {
    static let settings = AppSettings()
    
    //  Called when changing newProperties - new object tags
    var saveObjectClouser: (() -> Void)?
    //  Called when changing savedObjects - to update the map
    var mapVCClouser: (() -> Void)?
    //  It is called in case of writing a token upon successful authorization, for uploading user data.
    var userInfoClouser: ((OSMUserInfo) -> Void)?
    
//    MARK: OSM VARIABLES
    
    //  The variable into which the last MapView bbox is saved
    var lastBbox: GLMapBBox? {
        get {
            let orX = UserDefaults.standard.double(forKey: "bboxOrX")
            let orY = UserDefaults.standard.double(forKey: "bboxOrY")
            let sizeX = UserDefaults.standard.double(forKey: "bboxSizeX")
            let sizeY = UserDefaults.standard.double(forKey: "bboxSizeY")
            if orX != 0 && orY != 0 && sizeX != 0 && sizeY != 0 {
                let origin = GLMapPoint(x: orX, y: orY)
                let size = GLMapPoint(x: sizeX, y: sizeY)
                let bbox = GLMapBBox(origin: origin, size: size)
                return bbox
            } else {
                return nil
            }
        }
        set {
            let newBbox = newValue ?? GLMapBBox(origin: GLMapPoint(x: 0, y: 0), size: GLMapPoint(x: 0, y: 0))
            UserDefaults.standard.set(newBbox.origin.x, forKey: "bboxOrX")
            UserDefaults.standard.set(newBbox.origin.y, forKey: "bboxOrY")
            UserDefaults.standard.set(newBbox.size.x, forKey: "bboxSizeX")
            UserDefaults.standard.set(newBbox.size.y, forKey: "bboxSizeY")
        }
    }

    //  Specifies which server to work with - working or test
    var isDevServer: Bool {
        get {
            UserDefaults.standard.bool(forKey: "isDevServer")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isDevServer")
        }
    }
    
    var server: String {
        if isDevServer {
            return "https://master.apis.dev.openstreetmap.org"
        } else {
            return "https://api.openstreetmap.org"
        }
    }
    
    var authServer: String {
        if isDevServer {
            return "https://master.apis.dev.openstreetmap.org"
        } else {
            return "https://www.openstreetmap.org"
        }
    }
    
    var token: String? {
        get {
            if isDevServer {
                return UserDefaults.standard.string(forKey: "dev_access_token")
            } else {
                return UserDefaults.standard.string(forKey: "access_token")
            }
        }
        set {
            if newValue == nil {
                userName = nil
            }
            if isDevServer {
                UserDefaults.standard.set(newValue, forKey: "dev_access_token")
            } else {
                UserDefaults.standard.set(newValue, forKey: "access_token")
            }
//          When saving the token, it loads the user's data
            Task {
                do {
                    let userInfo = try await OsmClient().getUserInfo()
                    if let clouser = userInfoClouser {
                        clouser(userInfo)
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
    
    var userName: String? {
        get {
            if isDevServer {
                return UserDefaults.standard.string(forKey: "dev_userName")
            } else {
                return UserDefaults.standard.string(forKey: "userName")
            }
        }
        set {
            if isDevServer {
                UserDefaults.standard.set(newValue, forKey: "dev_userName")
            } else {
                UserDefaults.standard.set(newValue, forKey: "userName")
            }
        }
    }
    
    var clienID: String {
        if isDevServer {
            return ApiKeys.devClientID
        } else {
            return ApiKeys.prodClienID
        }
    }
    
    var clientSecret: String {
        if isDevServer {
            return ApiKeys.devClientSecret
        } else {
            return ApiKeys.prodClientSecret
        }
    }
    
    //  Gives a unique id that is applied to the created objects.
    var nextID: Int {
        let i = UserDefaults.standard.integer(forKey: "nextNodeID")
        if i == 0 {
            UserDefaults.standard.set(-2, forKey: "nextNodeID")
            return -1
        } else {
            UserDefaults.standard.set(i - 1, forKey: "nextNodeID")
            return i
        }
    }
    
    // the variable in which the comment is written, which the user assigns to changeset. Used on EditVC, SavedNodesVC and OsmClient
    var changeSetComment: String?
    
//    MARK: MAP STYLES

    //  Displays the loaded OSM data.
    let defaultStyle = """
    node {
        icon-image: "poi_circle_small.svg";
        icon-scale: 2;
        icon-tint: blue;
        text: eval(tag('text'));
        text-color: red;
        font-size: 12;
        text-priority: 20;
        [fixme] { icon-tint: red;}
    }
    
    line {
        linecap: round;
        width: 3pt;
        color:brown;
    }
    area {
        width:3pt;
        color:black;
    }
    """
    
    //  Displays objects that have been modified but not sent to the server (green).
    let savedStyle = """
    node {
        icon-image: "poi_circle_small.svg";
        icon-scale: 2;
        icon-tint: green;
    }
    line {
        linecap: round;
        width: 3pt;
        color:green;
    }
    """
    
    //  Displays the object that was tapped and whose properties are currently being edited (yellow).
    let editStyle = """
    node {
        icon-image: "poi_circle_small.svg";
        icon-scale: 1;
        icon-tint: yellow;
    }
    line {
        linecap: round;
        width: 3pt;
        color:yellow;
    }
    area {
        width:3pt;
        color:yellow;
    }
    """
    
    //  Displays objects created but not sent to the server (orange color).
    let newStyle = """
    node {
        icon-image: "poi_circle_small.svg";
        icon-scale: 2;
        icon-tint: orange;
    }
    line {
        linecap: round;
        width: 3pt;
        color:orange;
    }
    """
    
    //  Highlights objects that fell under the tap, if there was not one object under the tap, but several.
    let tappedStyle = """
    node {
        icon-image: "poi_circle_small.svg";
        icon-scale: 2;
        icon-tint: orange;
    }
    line {
        linecap: round;
        width: 4pt;
        color:orange;
    }
    """
    
//    MARK: PRESETS

    var chunks: [String: [ItemElements]] = [:]
    
    var categories: [Category] = []
    
    var itemPathes: [[String: String]: ItemPath] = [:]
    
//    MARK: FILE PATHES
    
    // Path to a file that stores modified and created objects
    let savedNodesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("savedNodes.data")
    
    // Path to a file that stores objects marked for deletion
    let deletedNodesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("deletedNodes.data")
    
    // Pathes to files with XML (input) and geoJSON (output) data of central bbox (user screen)
    let inputFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("input.xml")
    let outputFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("data.geojson")
    
    //  Stores objects downloaded from OSM server
    var inputObjects: [Int: Any] = [:]
    
    //  Stores and writes created and modified objects to a file
    var savedObjects: [Int: OSMAnyObject] = [:] {
        didSet {
            if let clouser = mapVCClouser {
                clouser()
            }
            do {
                let data = try JSONEncoder().encode(savedObjects)
                try data.write(to: savedNodesURL, options: .atomic)
            } catch {
                print("Error while write saved objects: ", error)
            }
        }
    }
    
    // Objects marked for deletion
    var deletedObjects: [Int: OSMAnyObject] = [:] {
        didSet {
            if let clouser = mapVCClouser {
                clouser()
            }
            do {
                let data = try JSONEncoder().encode(deletedObjects)
                try data.write(to: deletedNodesURL, options: .atomic)
            } catch {
                print("Error while write saved objects: ", error)
            }
        }
    }
    
    //  Fills savedObjects and deletedObjects with objects from the file when the application starts
    func getSavedObjects() {
        do {
            let data = try Data(contentsOf: savedNodesURL)
            savedObjects = try JSONDecoder().decode([Int: OSMAnyObject].self, from: data)
        } catch {
            savedObjects = [:]
        }
        do {
            let data = try Data(contentsOf: deletedNodesURL)
            deletedObjects = try JSONDecoder().decode([Int: OSMAnyObject].self, from: data)
        } catch {
            deletedObjects = [:]
        }
    }
    
//    MARK: PUBLUC BUFFER VARIABLES

    //  When changing newProperties, a closure is triggered, which saves the object to memory on the tag editing controller. In some cases, there is no need to do this, then saveAllowed changes.
    var saveAllowed = false
    //  Stores new object tags. Reset to zero when the tag editing controller is closed.
    var newProperties: [String: String] = [:] {
        didSet {
            if let clouser = saveObjectClouser {
                clouser()
            }
        }
    }
}
