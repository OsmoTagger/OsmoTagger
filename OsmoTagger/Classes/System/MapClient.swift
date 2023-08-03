//
//  Map.swift
//  OSM editor
//
//  Created by Arkadiy on 23.02.2023.
//

import GLMap
import GLMapCore
import UIKit
import XMLCoder

// Class for work with mapView. Later it is necessary to transfer all map objects to it
class MapClient {
    weak var delegate: MapClientProtocol?
    
    // Since the getSourceBbox data loading method is launched when the screen is shifted, we use lock to block simultaneous access to variables.
    let lock = NSLock()
    // A dictionary that stores the unique id of the upload operation
    var openOperations: [Int: Bool] = [:]
    // Variable to give each load operation a unique id
    var lastID: Int = 0
    var operationID: Int {
        let number = lastID + 1
        lastID = number
        return number
    }
    
    let fileManager = FileManager.default
    
    // All vector objects on the map are added to the array, to search for objects under the tap
    var tapObjects = GLMapVectorObjectArray()
        
    // Drawble objects and styles to display data on MapView
    // Layer with original OSM map data
    let sourceDrawble = GLMapVectorLayer(drawOrder: 0)
    let sourceStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.defaultStyle)
    //  Displays objects that have been modified but not sent to the server (green).
    let savedDrawable = GLMapVectorLayer(drawOrder: 1)
    let savedStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.savedStyle)
    //  Highlights objects that fell under the tap, if there was not one object under the tap, but several.
    let tappedDrawble = GLMapVectorLayer(drawOrder: 3)
    let tappedStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.tappedStyle)
    
    // Link to SavedNodesButton on MapViewController to update counter
    var savedNodeButtonLink: SavedObjectButton?
    
    // Latest options bbox loading raw map data
    var lastCenter: GLMapGeoPoint?
    // This is the default bbox size for loading OSM raw data. In case of receiving a response from the server "400" - too many objects in the bbox (may occur in regions with a high density of objects) is reduced by 25%
    var defaultBboxSize = 0.004
     
    init() {
        setAppSettingsClouser()
        // Reading the modified and created objects into the AppSettings.settings.savedObjects variable.
        AppSettings.settings.getSavedObjects()
        // In the background, we start parsing the file with Josm presets.
        loadPresets()
    }
    
    func loadPresets() {
        DispatchQueue.global(qos: .default).async {
            Parser().fillPresetElements()
            Parser().fillChunks()
        }
    }
    
    func setAppSettingsClouser() {
        // Every time AppSettings.settings.savedObjects is changed (this is the variable in which the modified or created objects are stored), a closure is called. In this case, when a short circuit is triggered, we update the illumination of saved and created objects.
        AppSettings.settings.mapVCClouser = { [weak self] in
            guard let self = self else { return }
            self.showSavedObjects()
        }
    }
    
    // The method is called from a closure on the MapViewController to load data in case the map moves out of the area of previously loaded data
    //    ---------latMax
    //   |           |
    //   |           |
    //   |           |
    // lonMin------lonMax/latMin
    func checkMapCenter(center: GLMapGeoPoint) async throws {
        if let lastCenter = lastCenter {
            let longMin = lastCenter.lon - defaultBboxSize
            let longMax = lastCenter.lon + defaultBboxSize
            let latMin = lastCenter.lat - defaultBboxSize
            let latMax = lastCenter.lat + defaultBboxSize
            if center.lon < longMin || center.lon > longMax || center.lat < latMin || center.lat > latMax {
                // When we call the new load method, we remove all values from the dictionary of operations to block them.
                try await startNewDownload(center: center)
            }
        } else {
            lastCenter = center
            try await startNewDownload(center: center)
        }
    }
    
    func startNewDownload(center: GLMapGeoPoint) async throws {
        lock.lock()
        openOperations.removeAll()
        lock.unlock()
        try await getSourceBbox(mapCenter: center)
    }
    
    // Loading the source data of the map in the bbox
    func getSourceBbox(mapCenter: GLMapGeoPoint) async throws {
        if defaultBboxSize < 0.0005 {
            defaultBboxSize = 0.002
        }
        let id = operationID
        // Run indicator animation in MapViewController
        delegate?.startDownload()
        // Adding an operation to the dictionary of running operations
        lock.lock()
        openOperations[id] = true
        lock.unlock()

        // Create tmp directory and file for converting OSM xml to geoJSON and indexing it
        let xmlFileName = ProcessInfo().globallyUniqueString
        let xmlFileURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(xmlFileName + ".osm")
        let jsonFileName = ProcessInfo().globallyUniqueString
        let jsonFileURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(jsonFileName + ".geojson")
        defer {
            if fileManager.fileExists(atPath: xmlFileURL.path) {
                try? fileManager.removeItem(at: xmlFileURL)
            }
            if fileManager.fileExists(atPath: jsonFileURL.path) {
                try? fileManager.removeItem(at: jsonFileURL)
            }
        }
        
        // Setting a maximum bbox size to prevent getting a 400 error from the server
        let latitudeDisplayMin = mapCenter.lat - defaultBboxSize
        let latitudeDisplayMax = mapCenter.lat + defaultBboxSize
        let longitudeDisplayMin = mapCenter.lon - defaultBboxSize
        let longitudeDisplayMax = mapCenter.lon + defaultBboxSize
        // Get data from server
        var nilData: Data?
        do {
            nilData = try await OsmClient().downloadOSMData(longitudeDisplayMin: longitudeDisplayMin, latitudeDisplayMin: latitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax, latitudeDisplayMax: latitudeDisplayMax)
        } catch OsmClientErrors.objectLimit {
            // Reduce bbox size to reduce the number of loaded objects
            print("--------------------Objects limit---------------------------")
            lock.lock()
            defaultBboxSize = defaultBboxSize * 0.75
            openOperations.removeAll()
            lock.unlock()
            try await getSourceBbox(mapCenter: mapCenter)
        }
        lock.lock()
        if openOperations[id] == nil {
            print("2-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        // Write data to file
        guard let data = nilData else { throw "Error get data - nill data" }
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.getNodesFromXML(data: data)
        }
        lock.lock()
        if openOperations[id] == nil {
            print("3-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        try data.write(to: xmlFileURL)
        // Convert OSM xml to geoJSON
        if let error = osmium_convert(xmlFileURL.path, jsonFileURL.path) {
            throw "Error osmium convert: \(error). Try move map center and load data again."
        }
        lock.lock()
        if openOperations[id] == nil {
            print("4-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        let dataGeojson = try Data(contentsOf: jsonFileURL)
        lock.lock()
        if openOperations[id] == nil {
            print("5-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        // Make vector objects from geoJSON
        let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
        // add a border around the loaded data
        if !AppSettings.settings.sourceFrameisHidden {
            let points = GLMapPointArray()
            let pt1 = GLMapPoint(lat: latitudeDisplayMax, lon: longitudeDisplayMin)
            points.add(pt1)
            let pt2 = GLMapPoint(lat: latitudeDisplayMax, lon: longitudeDisplayMax)
            points.add(pt2)
            let pt3 = GLMapPoint(lat: latitudeDisplayMin, lon: longitudeDisplayMax)
            points.add(pt3)
            let pt4 = GLMapPoint(lat: latitudeDisplayMin, lon: longitudeDisplayMin)
            points.add(pt4)
            points.add(pt1)
            let line = GLMapVectorLine(line: points)
            line.setValue("map", forKey: "bbox")
            newObjects.add(line)
        }
        lock.lock()
        if openOperations[id] == nil {
            print("6-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        // Add new objects to array for tap
        lock.lock()
        tapObjects = newObjects
        for (_, object) in AppSettings.settings.savedObjects {
            tapObjects.add(object.vector)
        }
        if openOperations[id] == nil {
            print("7-", id)
            lock.unlock()
            return
        }
        lock.unlock()
        // Add layer on MapViewController
        delegate?.removeDrawble(layer: sourceDrawble)
        if let style = sourceStyle {
            lock.lock()
            sourceDrawble.setVectorObjects(newObjects, with: style, completion: nil)
            lock.unlock()
            delegate?.addDrawble(layer: sourceDrawble)
        }
        lock.lock()
        lastCenter = mapCenter
        if openOperations[id] == nil {
            print("8-", id)
            lock.unlock()
            return
        }
        lock.unlock()
    }
    
    //  In the background, we start indexing the downloaded data and saving them with the dictionary appSettings.settings.inputObjects for quick access to the object by its id.
    func getNodesFromXML(data: Data) {
        let id = operationID
        lock.lock()
        openOperations[id] = false
        lock.unlock()
        let parser = XMLParser(data: data)
        let parserDelegate = OSMXmlParser()
        parser.delegate = parserDelegate
        parser.parse()
        lock.lock()
        AppSettings.settings.inputObjects = parserDelegate.objects
        lock.unlock()
        delegate?.endDownload()
    }
    
    func getObjectType(object: GLMapVectorObject) -> GLMapVectoObjectType? {
        if object is GLMapVectorPoint || object is GLMapVectorLine {
            return .simple
        } else if let polygon = object as? GLMapVectorPolygon {
            let line = polygon.buildOutline() // GLMapVectorLine
            return .polygon(line: line)
        } else {
            return nil
        }
    }
    
    //  Get objects after tap
    func openObject(touchCoordinate: GLMapPoint, tmp: GLMapPoint) -> [OSMAnyObject] {
        var tappedVectorObjects: [GLMapVectorObject] = []
        var uniqTappedObjects: [GLMapVectorObject] = []
        var uniqTappedObjectsIDs: [Int] = []
        var result: [OSMAnyObject] = []
        let maxDist = CGFloat(hypot(tmp.x, tmp.y))
        var nearestPoint = GLMapPoint()
        guard tapObjects.count > 0 else { return [] }
        for i in 0 ... tapObjects.count - 1 {
            let object = tapObjects[i]
            if object.findNearestPoint(&nearestPoint, to: touchCoordinate, maxDistance: maxDist) {
                let type = getObjectType(object: object)
                switch type {
                case .simple:
                    tappedVectorObjects.append(object)
                case let .polygon(line):
                    if line.findNearestPoint(&nearestPoint, to: touchCoordinate, maxDistance: maxDist) {
                        tappedVectorObjects.append(object)
                    }
                case .none:
                    continue
                }
            }
        }
        for object in tappedVectorObjects {
            guard let id = object.getObjectID() else { continue }
            if uniqTappedObjectsIDs.contains(id) == false {
                uniqTappedObjectsIDs.append(id)
                uniqTappedObjects.append(object)
            }
        }
        for vectorObject in uniqTappedObjects {
            guard let id = vectorObject.getObjectID() else { continue }
            if let object = AppSettings.settings.savedObjects[id] {
                result.append(object)
            } else if let node = AppSettings.settings.inputObjects[id] as? Node {
                let object = OSMAnyObject(type: .node, id: node.id, version: node.version, changeset: node.changeset, lat: node.lat, lon: node.lon, tag: node.tag, nd: [], nodes: [:], members: [], vector: vectorObject)
                result.append(object)
            } else if let way = AppSettings.settings.inputObjects[id] as? Way {
                var nodes: [Int: Node] = [:]
                for id in way.nd {
                    guard let node = AppSettings.settings.inputObjects[id.ref] as? Node else { continue }
                    nodes[node.id] = node
                }
                if way.nd[0].ref == way.nd.last?.ref {
                    let object = OSMAnyObject(type: .closedway, id: way.id, version: way.version, changeset: way.changeset, lat: nil, lon: nil, tag: way.tag, nd: way.nd, nodes: nodes, members: [], vector: vectorObject)
                    result.append(object)
                } else {
                    let object = OSMAnyObject(type: .way, id: way.id, version: way.version, changeset: way.changeset, lat: nil, lon: nil, tag: way.tag, nd: way.nd, nodes: nodes, members: [], vector: vectorObject)
                    result.append(object)
                }
            } else if let relation = AppSettings.settings.inputObjects[id] as? Relation {
                let object = OSMAnyObject(type: .multipolygon, id: relation.id, version: relation.version, changeset: relation.changeset, lat: nil, lon: nil, tag: relation.tag, nd: [], nodes: [:], members: relation.member, vector: vectorObject)
                result.append(object)
            }
        }
        if result.count > 1 {
            highLightTappedObjects(objects: result)
        }
        return result
    }
    
    //  Calls the object selection controller if there are several of them under the tap.
    func highLightTappedObjects(objects: [OSMAnyObject]) {
        delegate?.removeDrawble(layer: tappedDrawble)
        let tappedObjects = GLMapVectorObjectArray()
        for object in objects {
            tappedObjects.add(object.vector)
        }
        if let style = tappedStyle {
            tappedDrawble.setVectorObjects(tappedObjects, with: style, completion: nil)
        }
        delegate?.addDrawble(layer: tappedDrawble)
    }
    
    //  Displays created and modified objects.
    func showSavedObjects() {
        let savedObjects = GLMapVectorObjectArray()
        for (id, osmObject) in AppSettings.settings.savedObjects {
            let object = osmObject.vector
            // The ID is stored as a string in each vector object (feature of how osmium works). To recognize the id of the created object after the tap, assign it a number
            object.setValue(String(id), forKey: "@id")
            savedObjects.add(object)
        }
        if savedObjects.count > 0 {
            for i in 0 ... savedObjects.count - 1 {
                let object = savedObjects[i]
                tapObjects.add(object)
            }
        }
        delegate?.removeDrawble(layer: savedDrawable)
        if let savedStyle = savedStyle {
            savedDrawable.setVectorObjects(savedObjects, with: savedStyle, completion: nil)
        }
        delegate?.addDrawble(layer: savedDrawable)
        // Update saveNodesButton counter
        if let button = savedNodeButtonLink {
            DispatchQueue.main.async {
                button.update()
            }
        }
    }
}
