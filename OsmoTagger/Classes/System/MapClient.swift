//
//  MapClient.swift
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
            
    let fileManager = FileManager.default
    
    // All vector objects on the map are added to the array, to search for objects under the tap
    var tapObjects = GLMapVectorObjectArray()
        
    // Drawble objects and styles to display data on MapView
    // Layer with original OSM map data
    let sourceDrawble = GLMapVectorLayer(drawOrder: 0)
    //  Displays objects that have been modified but not sent to the server (green).
    let savedDrawable = GLMapVectorLayer(drawOrder: 1)
    //  Highlights objects that fell under the tap, if there was not one object under the tap, but several.
    let tappedDrawble = GLMapVectorLayer(drawOrder: 3)
    
    // Latest options bbox loading raw map data
    var lastCenter: GLMapGeoPoint?
    // This is the default bbox size for loading OSM raw data. In case of receiving a response from the server "400" - too many objects in the bbox (may occur in regions with a high density of objects) is reduced by 25%
    var defaultBboxSize = 0.0045
     
    init() {
        Log("--------------")
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-YYYY HH:mm:ss"
        let dateStr = dateFormatter.string(from: date)
        Log("App start at \(dateStr)")
        Log("Is dev server active = \(AppSettings.settings.isDevServer)")
        setAppSettingsClouser()
        // In the background, we start parsing the file with Josm presets.
        loadPresets()
    }
    
    func loadPresets() {
        DispatchQueue.global(qos: .default).async {
            Parser().fillPresetElements()
            let presetCount = AppSettings.settings.itemPathes.count
            Log("\(presetCount) presets found")
            Parser().fillChunks()
            let chunkCount = AppSettings.settings.chunks.count
            Log("\(chunkCount) chunks found")
        }
    }
    
    func setAppSettingsClouser() {
        // Every time AppSettings.settings.savedObjects is changed (this is the variable in which the modified or created objects are stored), a closure is called. In this case, when a short circuit is triggered, we update the illumination of saved and created objects.
        AppSettings.settings.showSavedObjectClosure = { [weak self] in
            guard let self = self else { return }
            self.showSavedObjects()
        }
    }
    
    func checkMapcenter(center: GLMapGeoPoint) -> Bool {
        guard let lastCenter = lastCenter else {
            return false
        }
        let longMin = lastCenter.lon - defaultBboxSize
        let longMax = lastCenter.lon + defaultBboxSize
        let latMin = lastCenter.lat - defaultBboxSize
        let latMax = lastCenter.lat + defaultBboxSize
        return !(center.lon < longMin || center.lon > longMax || center.lat < latMin || center.lat > latMax)
    }
    
    // Loading the source data of the map in the bbox
    func getSourceBbox(mapCenter: GLMapGeoPoint) async throws {
        // Run indicator animation in MapViewController
        delegate?.startDownload()
        // Setting a maximum bbox size to prevent getting a 400 error from the server
        let latitudeDisplayMin = mapCenter.lat - defaultBboxSize
        let latitudeDisplayMax = mapCenter.lat + defaultBboxSize
        let longitudeDisplayMin = mapCenter.lon - defaultBboxSize
        let longitudeDisplayMax = mapCenter.lon + defaultBboxSize
        // Get data from server
        let data = try await OsmClient.client.downloadOSMData(longitudeDisplayMin: longitudeDisplayMin, latitudeDisplayMin: latitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax, latitudeDisplayMax: latitudeDisplayMax)
        try parseData(data: data, latitudeDisplayMin: latitudeDisplayMin, latitudeDisplayMax: latitudeDisplayMax, longitudeDisplayMin: longitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax)
        lastCenter = mapCenter
    }
    
    func parseData(data: Data, latitudeDisplayMin: Double? = nil, latitudeDisplayMax: Double? = nil, longitudeDisplayMin: Double? = nil, longitudeDisplayMax: Double? = nil) throws {
        try showGeoJson(data: data, latitudeDisplayMin: latitudeDisplayMin, latitudeDisplayMax: latitudeDisplayMax, longitudeDisplayMin: longitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax)
        getNodesFromXML(data: data)
    }
    
    private func showGeoJson(data: Data, latitudeDisplayMin: Double?, latitudeDisplayMax: Double?, longitudeDisplayMin: Double?, longitudeDisplayMax: Double?) throws {
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
        // Convert OSM xml to geoJSON
        try data.write(to: xmlFileURL)
        if let error = osmium_convert(xmlFileURL.path, jsonFileURL.path) {
            throw "Error osmium convert: \(error). Try move map center and load data again."
        }
        
        let dataGeojson = try Data(contentsOf: jsonFileURL)
        
        // Make vector objects from geoJSON
        let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
        // add a border around the loaded data
        if !AppSettings.settings.sourceFrameisHidden,
           let latitudeDisplayMin,
           let latitudeDisplayMax,
           let longitudeDisplayMin,
           let longitudeDisplayMax
        {
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
        // Add new objects to array for tap
        tapObjects = newObjects
        for (_, object) in AppSettings.settings.savedObjects {
            tapObjects.add(object.vector)
        }
        // Add layer on MapViewController
        delegate?.removeDrawble(layer: sourceDrawble)
        sourceDrawble.setVectorObjects(newObjects, with: MapStyles.sourceStyle, completion: nil)
        delegate?.addDrawble(layer: sourceDrawble)
    }
    
    //  In the background, we start indexing the downloaded data and saving them with the dictionary appSettings.settings.inputObjects for quick access to the object by its id.
    private func getNodesFromXML(data: Data) {
        let parser = XMLParser(data: data)
        let parserDelegate = OSMXmlParser()
        parser.delegate = parserDelegate
        parser.parse()
        AppSettings.settings.inputObjects = parserDelegate.objects
        delegate?.endDownload()
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
                let type = object.getType()
                switch type {
                case .simple:
                    tappedVectorObjects.append(object)
                case let .polygon(line):
                    if line.findNearestPoint(&nearestPoint, to: touchCoordinate, maxDistance: maxDist) {
                        tappedVectorObjects.append(object)
                    }
                case .unknown:
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
        tappedDrawble.setVectorObjects(tappedObjects, with: MapStyles.tappedStyle, completion: nil)
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
        savedDrawable.setVectorObjects(savedObjects, with: MapStyles.savedStyle, completion: nil)
        delegate?.addDrawble(layer: savedDrawable)
    }
}
