//
//  AppSettings.swift
//  OSM editor
//
//  Created by Arkadiy on 11.11.2022.
//

import GLMap
import UIKit

//  Singleton for storing app settings
final class AppSettings: NSObject {
    static let settings = AppSettings()
    
    // Reading the modified and created objects into the AppSettings.settings.savedObjects variable.
    override init() {
        do {
            let data = try Data(contentsOf: savedNodesURL)
            savedObjects = try JSONDecoder().decode([Int: OSMAnyObject].self, from: data)
        } catch {
            // When initializing AppSettings.settings, we cannot use the Log function. Only after initialization.
            logs.append("Error init savedObjects: \(error)")
            savedObjects = [:]
        }
        do {
            let data = try Data(contentsOf: deletedNodesURL)
            deletedObjects = try JSONDecoder().decode([Int: OSMAnyObject].self, from: data)
        } catch {
            logs.append("Error init deletedObjects: \(error)")
            deletedObjects = [:]
        }
        do {
            let data = try Data(contentsOf: logsURL)
            var lastLogs = try JSONDecoder().decode([String].self, from: data)
            if lastLogs.count > 1000 {
                lastLogs = Array(lastLogs.prefix(99))
            }
            logs += lastLogs
        } catch {
            logs.append("Error init logs: \(error)")
            logs = []
        }
    }
    
    //  Called when changing savedObjects - to update the map
    var mapVCClouser: EmptyBlock?
    // Closure that is called in the MapClient class to display or delete a vector object
    var showVectorObjectClosure: ((GLMapVectorObject?) -> Void)?
    
    // A vector object is written to this variable, which must be displayed on the map at the time of editing (the editStyle style is yellow).
    // When opening EditObjectVC, a vector object is written, and through a variable is passed to mapClient, which adds and deletes the object
    var editableObject: GLMapVectorObject? {
        didSet {
            if let closure = showVectorObjectClosure {
                closure(editableObject)
            }
        }
    }
    
    // MARK: MAIN SCREEN SETTINGS

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
    
    // Called when the user changes the display or hide settings for zoom buttons.
    var showMapButtonsClosure: ((Bool) -> Void)?
    // Variable for displaying navigation buttons on MapVC
    var mapButtonsIsHidden: Bool {
        get {
            let value = UserDefaults.standard.bool(forKey: "mapButtonsIsHidden")
            return value
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "mapButtonsIsHidden")
            showMapButtonsClosure?(newValue)
        }
    }

    // Variable for displaying the border of loaded data.
    var sourceFrameisHidden: Bool {
        get {
            let value = UserDefaults.standard.bool(forKey: "sourceFrameisHidden")
            return value
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "sourceFrameisHidden")
        }
    }
    
    // MARK: OSM VARIABLES

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
            } else {
                Task {
                    let userInfo = try? await OsmClient().getUserInfo()
                    if let userInfo {
                        userName = userInfo.user.display_name
                    }
                }
            }
            if isDevServer {
                UserDefaults.standard.set(newValue, forKey: "dev_access_token")
            } else {
                UserDefaults.standard.set(newValue, forKey: "access_token")
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
    
    // MARK: PRESETS

    var chunks: [String: [ItemElements]] = [:]
    
    var categories: [Category] = []
    
    var itemPathes: [[String: String]: ItemPath] = [:]
    
    // MARK: FILE PATHES
    
    // Path to a file that stores modified and created objects
    let savedNodesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("savedNodes.data")
    
    // Path to a file that stores objects marked for deletion
    let deletedNodesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("deletedNodes.data")
    
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
                let text = "Error while write saved objects: \(error)"
                Alert.showAlert(text)
                Log(text)
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
                let text = "Error while write saved objects: \(error)"
                Log(text)
                Alert.showAlert(text)
            }
        }
    }
    
    // MARK: LOGS

    private let logsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logs.data")
    var logs: [String] = [] {
        didSet {
            do {
                let data = try JSONEncoder().encode(logs)
                try data.write(to: logsURL, options: .atomic)
            } catch {
                Alert.showAlert("Error write logs: \(error)")
            }
        }
    }
}
