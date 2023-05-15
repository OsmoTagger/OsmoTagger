//
//  Map.swift
//  OSM editor
//
//  Created by Arkadiy on 23.02.2023.
//

import GLMap
import GLMapCore
import UIKit

// Class for work with mapView. Later it is necessary to transfer all map objects to it
class MapClient: NSObject {
    var objects = GLMapVectorObjectArray()
    var objectsLength = UInt(0)
    
    //  Load data and write to files
    func getSourceData(longitudeDisplayMin: Double, latitudeDisplayMin: Double, longitudeDisplayMax: Double, latitudeDisplayMax: Double) async throws {
        let data = try await OsmClient.client.downloadOSMData(longitudeDisplayMin: longitudeDisplayMin, latitudeDisplayMin: latitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax, latitudeDisplayMax: latitudeDisplayMax)
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL.path) {
                try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL.path)
            }
            if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL.path) {
                try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL.path)
            }
            try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL.path))
            if let error = osmium_convert(AppSettings.settings.inputFileURL.path, AppSettings.settings.outputFileURL.path) {
                throw "Error osmium convert: \(error)"
            }
        } catch {
            throw "Error write file: \(error)"
        }
    }
    
    //  Get objects after tap
    func openObject(touchCoordinate: GLMapPoint, tmp: GLMapPoint) -> Set<Int> {
        var result: Set<Int> = []
        let maxDist = CGFloat(hypot(tmp.x, tmp.y))
        var nearestPoint = GLMapPoint()
        var selectedIndex: [UInt] = []
        let objectIndex = objects.count - 1
        for i in 0 ... objectIndex {
            let object = objects[i]
            if object.findNearestPoint(&nearestPoint, to: touchCoordinate, maxDistance: maxDist) && (object.type.rawValue == 1 || object.type.rawValue == 2) {
                selectedIndex.append(i)
            }
        }
        for index in selectedIndex {
            let object = objects[index]
            guard let id = object.getObjectID() else { continue }
            result.insert(id)
        }
        return result
    }
}
