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
    // Download objects
    var tapObjects: [GLMapVectorObjectArray] = []
    let fileManager = FileManager.default
    
    var addDrawbleClouser: ((GLMapDrawable) -> Void)?
    var deleteDrawbleClouser: ((GLMapDrawable) -> Void)?
    
    // Variable save showed layers.
    // 0...8 - layers with source data
    // 9 - created objects
    // 10 - edited objects
    var showedDrawable: [Int: GLMapDrawable] = [:]
    
    //  Drawble objects and styles to display data on MapView.
    let sourceStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.defaultStyle)
    //  Displays objects created but not sent to the server (orange color).
    let newStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.newStyle)
    //  Displays objects that have been modified but not sent to the server (green).
    let savedStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.savedStyle)
    
    init() {
        setAppSettingsClouser()
    }
    
    func setAppSettingsClouser() {
        // Every time AppSettings.settings.savedObjects is changed (this is the variable in which the modified or created objects are stored), a closure is called. In this case, when a short circuit is triggered, we update the illumination of saved and created objects.
        AppSettings.settings.mapVCClouser = { [weak self] in
            guard let self = self else { return }
            self.showSavedObjects()
        }
    }
    
    // Loading the source data of the map surrounding the bbox
    // 1 2 3
    // 8 0 4
    // 7 6 5
    func getSourceSurround(longitudeDisplayMin: Double, latitudeDisplayMin: Double, longitudeDisplayMax: Double, latitudeDisplayMax: Double) async {
        print("getSourceSurround")
        let latitudeDiff = latitudeDisplayMax - latitudeDisplayMin
        let longitudeDiff = longitudeDisplayMax - longitudeDisplayMin
        let arr = [latitudeDiff, longitudeDiff]
        guard let diff = arr.min() else {return}
        await withTaskGroup(of: Void.self, body: { [weak self] group in
            guard let self = self else {return}
            group.addTask {
                await self.getBboxSourceData(longitudeDisplayMin: longitudeDisplayMin, latitudeDisplayMin: latitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax, latitudeDisplayMax: latitudeDisplayMax, index: 0)
            }
            group.addTask {
                await self.getBboxSourceData(longitudeDisplayMin: longitudeDisplayMin - diff, latitudeDisplayMin: latitudeDisplayMax, longitudeDisplayMax: longitudeDisplayMin, latitudeDisplayMax: latitudeDisplayMax + diff, index: 1)
            }
            group.addTask {
                await self.getBboxSourceData(longitudeDisplayMin: longitudeDisplayMin, latitudeDisplayMin: latitudeDisplayMax, longitudeDisplayMax: longitudeDisplayMax, latitudeDisplayMax: latitudeDisplayMax + diff, index: 2)
            }
            group.addTask {
                await self.getBboxSourceData(longitudeDisplayMin: longitudeDisplayMax, latitudeDisplayMin: latitudeDisplayMax, longitudeDisplayMax: longitudeDisplayMax + diff, latitudeDisplayMax: latitudeDisplayMax + diff, index: 3)
            }
            group.addTask {
                await self.getBboxSourceData(longitudeDisplayMin: longitudeDisplayMax, latitudeDisplayMin: latitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax + diff, latitudeDisplayMax: latitudeDisplayMax, index: 4)
            }
            group.addTask {
                await self.getBboxSourceData(longitudeDisplayMin: longitudeDisplayMax, latitudeDisplayMin: latitudeDisplayMin - diff, longitudeDisplayMax: longitudeDisplayMax + diff, latitudeDisplayMax: latitudeDisplayMin, index: 5)
            }
            group.addTask {
                await self.getBboxSourceData(longitudeDisplayMin: longitudeDisplayMin, latitudeDisplayMin: latitudeDisplayMin - diff, longitudeDisplayMax: longitudeDisplayMax, latitudeDisplayMax: latitudeDisplayMin, index: 6)
            }
            group.addTask {
                await self.getBboxSourceData(longitudeDisplayMin: longitudeDisplayMin - diff, latitudeDisplayMin: latitudeDisplayMin - diff, longitudeDisplayMax: longitudeDisplayMin, latitudeDisplayMax: latitudeDisplayMin, index: 7)
            }
            group.addTask {
                await self.getBboxSourceData(longitudeDisplayMin: longitudeDisplayMin - diff, latitudeDisplayMin: latitudeDisplayMin - diff, longitudeDisplayMax: longitudeDisplayMin, latitudeDisplayMax: latitudeDisplayMax, index: 8)
            }
            await group.next()
        })
    }
    
    func getBboxSourceData(longitudeDisplayMin: Double, latitudeDisplayMin: Double, longitudeDisplayMax: Double, latitudeDisplayMax: Double, index: Int) async {
        var data: Data?
        do {
            data = try await OsmClient().downloadOSMData(longitudeDisplayMin: longitudeDisplayMin, latitudeDisplayMin: latitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax, latitudeDisplayMax: latitudeDisplayMax)
        } catch {
            print(error)
        }
        guard let data = data else {return}
        switch index {
        case 0:
            do {
                if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL.path)
                }
                if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL1.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL.path)
                }
                try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL.path))
                if let error = osmium_convert(AppSettings.settings.inputFileURL.path, AppSettings.settings.outputFileURL.path) {
                    throw "Error osmium convert: \(error)"
                }
                let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL)
                let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
                
                tapObjects.append(newObjects)
                let newDrawble = GLMapVectorLayer(drawOrder: 0)
                if let style = sourceStyle {
                    newDrawble.setVectorObjects(newObjects, with: style, completion: nil)
                    if let oldDrawble = showedDrawable[index],
                       let deleteClouser = deleteDrawbleClouser {
                        deleteClouser(oldDrawble)
                        showedDrawable[index] = nil
                    }
                    if let addClouser = addDrawbleClouser {
                        addClouser(newDrawble)
                        showedDrawable[index] = newDrawble
                    }
                }
            } catch {
                print("Error write file: \(error)")
            }
        case 1:
            do {
                if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL1.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL1.path)
                }
                if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL1.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL1.path)
                }
                try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL1.path))
                if let error = osmium_convert(AppSettings.settings.inputFileURL1.path, AppSettings.settings.outputFileURL1.path) {
                    throw "Error osmium convert: \(error)"
                }
                let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL1)
                let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
                
                tapObjects.append(newObjects)
                let newDrawble = GLMapVectorLayer(drawOrder: 0)
                if let style = sourceStyle {
                    newDrawble.setVectorObjects(newObjects, with: style, completion: nil)
                    if let oldDrawble = showedDrawable[index],
                       let deleteClouser = deleteDrawbleClouser {
                        deleteClouser(oldDrawble)
                        showedDrawable[index] = nil
                    }
                    if let addClouser = addDrawbleClouser {
                        addClouser(newDrawble)
                        showedDrawable[index] = newDrawble
                    }
                }
            } catch {
                print("Error write file: \(error)")
            }
        case 2:
            do {
                if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL2.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL2.path)
                }
                if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL2.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL2.path)
                }
                try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL2.path))
                if let error = osmium_convert(AppSettings.settings.inputFileURL2.path, AppSettings.settings.outputFileURL2.path) {
                    throw "Error osmium convert: \(error)"
                }
                let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL2)
                let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
                
                tapObjects.append(newObjects)
                let newDrawble = GLMapVectorLayer(drawOrder: 0)
                if let style = sourceStyle {
                    newDrawble.setVectorObjects(newObjects, with: style, completion: nil)
                    if let oldDrawble = showedDrawable[index],
                       let deleteClouser = deleteDrawbleClouser {
                        deleteClouser(oldDrawble)
                        showedDrawable[index] = nil
                    }
                    if let addClouser = addDrawbleClouser {
                        addClouser(newDrawble)
                        showedDrawable[index] = newDrawble
                    }
                }
            } catch {
                print("Error write file: \(error)")
            }
        case 3:
            do {
                if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL3.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL3.path)
                }
                if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL3.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL3.path)
                }
                try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL3.path))
                if let error = osmium_convert(AppSettings.settings.inputFileURL3.path, AppSettings.settings.outputFileURL3.path) {
                    throw "Error osmium convert: \(error)"
                }
                let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL3)
                let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
                
                tapObjects.append(newObjects)
                let newDrawble = GLMapVectorLayer(drawOrder: 0)
                if let style = sourceStyle {
                    newDrawble.setVectorObjects(newObjects, with: style, completion: nil)
                    if let oldDrawble = showedDrawable[index],
                       let deleteClouser = deleteDrawbleClouser {
                        deleteClouser(oldDrawble)
                        showedDrawable[index] = nil
                    }
                    if let addClouser = addDrawbleClouser {
                        addClouser(newDrawble)
                        showedDrawable[index] = newDrawble
                    }
                }
            } catch {
                print("Error write file: \(error)")
            }
        case 4:
            do {
                if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL4.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL4.path)
                }
                if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL4.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL4.path)
                }
                try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL4.path))
                if let error = osmium_convert(AppSettings.settings.inputFileURL4.path, AppSettings.settings.outputFileURL4.path) {
                    throw "Error osmium convert: \(error)"
                }
                let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL4)
                let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
                
                tapObjects.append(newObjects)
                let newDrawble = GLMapVectorLayer(drawOrder: 0)
                if let style = sourceStyle {
                    newDrawble.setVectorObjects(newObjects, with: style, completion: nil)
                    if let oldDrawble = showedDrawable[index],
                       let deleteClouser = deleteDrawbleClouser {
                        deleteClouser(oldDrawble)
                        showedDrawable[index] = nil
                    }
                    if let addClouser = addDrawbleClouser {
                        addClouser(newDrawble)
                        showedDrawable[index] = newDrawble
                    }
                }
            } catch {
                print("Error write file: \(error)")
            }
        case 5:
            do {
                if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL5.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL5.path)
                }
                if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL5.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL5.path)
                }
                try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL5.path))
                if let error = osmium_convert(AppSettings.settings.inputFileURL5.path, AppSettings.settings.outputFileURL5.path) {
                    throw "Error osmium convert: \(error)"
                }
                let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL5)
                let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
                
                tapObjects.append(newObjects)
                let newDrawble = GLMapVectorLayer(drawOrder: 0)
                if let style = sourceStyle {
                    newDrawble.setVectorObjects(newObjects, with: style, completion: nil)
                    if let oldDrawble = showedDrawable[index],
                       let deleteClouser = deleteDrawbleClouser {
                        deleteClouser(oldDrawble)
                        showedDrawable[index] = nil
                    }
                    if let addClouser = addDrawbleClouser {
                        addClouser(newDrawble)
                        showedDrawable[index] = newDrawble
                    }
                }
            } catch {
                print("Error write file: \(error)")
            }
        case 6:
            do {
                if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL6.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL6.path)
                }
                if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL6.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL6.path)
                }
                try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL6.path))
                if let error = osmium_convert(AppSettings.settings.inputFileURL6.path, AppSettings.settings.outputFileURL6.path) {
                    throw "Error osmium convert: \(error)"
                }
                let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL6)
                let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
                
                tapObjects.append(newObjects)
                let newDrawble = GLMapVectorLayer(drawOrder: 0)
                if let style = sourceStyle {
                    newDrawble.setVectorObjects(newObjects, with: style, completion: nil)
                    if let oldDrawble = showedDrawable[index],
                       let deleteClouser = deleteDrawbleClouser {
                        deleteClouser(oldDrawble)
                        showedDrawable[index] = nil
                    }
                    if let addClouser = addDrawbleClouser {
                        addClouser(newDrawble)
                        showedDrawable[index] = newDrawble
                    }
                }
            } catch {
                print("Error write file: \(error)")
            }
        case 7:
            do {
                if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL7.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL7.path)
                }
                if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL7.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL7.path)
                }
                try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL7.path))
                if let error = osmium_convert(AppSettings.settings.inputFileURL7.path, AppSettings.settings.outputFileURL7.path) {
                    throw "Error osmium convert: \(error)"
                }
                let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL7)
                let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
                
                tapObjects.append(newObjects)
                let newDrawble = GLMapVectorLayer(drawOrder: 0)
                if let style = sourceStyle {
                    newDrawble.setVectorObjects(newObjects, with: style, completion: nil)
                    if let oldDrawble = showedDrawable[index],
                       let deleteClouser = deleteDrawbleClouser {
                        deleteClouser(oldDrawble)
                        showedDrawable[index] = nil
                    }
                    if let addClouser = addDrawbleClouser {
                        addClouser(newDrawble)
                        showedDrawable[index] = newDrawble
                    }
                }
            } catch {
                print("Error write file: \(error)")
            }
        case 8:
            do {
                if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL8.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL8.path)
                }
                if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL8.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL8.path)
                }
                try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL8.path))
                if let error = osmium_convert(AppSettings.settings.inputFileURL8.path, AppSettings.settings.outputFileURL8.path) {
                    throw "Error osmium convert: \(error)"
                }
                let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL8)
                let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
                
                tapObjects.append(newObjects)
                let newDrawble = GLMapVectorLayer(drawOrder: 0)
                if let style = sourceStyle {
                    newDrawble.setVectorObjects(newObjects, with: style, completion: nil)
                    if let oldDrawble = showedDrawable[index],
                       let deleteClouser = deleteDrawbleClouser {
                        deleteClouser(oldDrawble)
                        showedDrawable[index] = nil
                    }
                    if let addClouser = addDrawbleClouser {
                        addClouser(newDrawble)
                        showedDrawable[index] = newDrawble
                    }
                }
            } catch {
                print("Error write file: \(error)")
            }
        case 9:
            do {
                if fileManager.fileExists(atPath: AppSettings.settings.inputFileURL9.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.inputFileURL9.path)
                }
                if fileManager.fileExists(atPath: AppSettings.settings.outputFileURL9.path) {
                    try fileManager.removeItem(atPath: AppSettings.settings.outputFileURL9.path)
                }
                try data.write(to: URL(fileURLWithPath: AppSettings.settings.inputFileURL9.path))
                if let error = osmium_convert(AppSettings.settings.inputFileURL9.path, AppSettings.settings.outputFileURL9.path) {
                    throw "Error osmium convert: \(error)"
                }
                let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL9)
                let newObjects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
                
                tapObjects.append(newObjects)
                let newDrawble = GLMapVectorLayer(drawOrder: 0)
                if let style = sourceStyle {
                    newDrawble.setVectorObjects(newObjects, with: style, completion: nil)
                    if let oldDrawble = showedDrawable[index],
                       let deleteClouser = deleteDrawbleClouser {
                        deleteClouser(oldDrawble)
                        showedDrawable[index] = nil
                    }
                    if let addClouser = addDrawbleClouser {
                        addClouser(newDrawble)
                        showedDrawable[index] = newDrawble
                    }
                }
            } catch {
                print("Error write file: \(error)")
            }
        default:
            return
        }
        await getNodesFromXML(index: index)
    }
    
    //  In the background, we start indexing the downloaded data and saving them with the dictionary appSettings.settings.inputObjects for quick access to the object by its id.
    func getNodesFromXML(index: Int) async {
        var data: Data?
        switch index {
        case 0:
            data = try? Data(contentsOf: AppSettings.settings.inputFileURL)
        case 1:
            data = try? Data(contentsOf: AppSettings.settings.inputFileURL1)
        case 2:
            data = try? Data(contentsOf: AppSettings.settings.inputFileURL2)
        case 3:
            data = try? Data(contentsOf: AppSettings.settings.inputFileURL3)
        case 4:
            data = try? Data(contentsOf: AppSettings.settings.inputFileURL4)
        case 5:
            data = try? Data(contentsOf: AppSettings.settings.inputFileURL5)
        case 6:
            data = try? Data(contentsOf: AppSettings.settings.inputFileURL6)
        case 7:
            data = try? Data(contentsOf: AppSettings.settings.inputFileURL7)
        case 8:
            data = try? Data(contentsOf: AppSettings.settings.inputFileURL8)
        default:
            return
        }
        guard let data = data else {return}
        do {
            let xmlObjects = try XMLDecoder().decode(osm.self, from: data)
            for node in xmlObjects.node {
                AppSettings.settings.inputObjects[node.id] = node
            }
            for way in xmlObjects.way {
                AppSettings.settings.inputObjects[way.id] = way
            }
        } catch {
            print(error)
        }
    }
    
    //  Get objects after tap
    func openObject(touchCoordinate: GLMapPoint, tmp: GLMapPoint) -> Set<Int> {
        print("openObject")
        var result: Set<Int> = []
        let maxDist = CGFloat(hypot(tmp.x, tmp.y))
        var nearestPoint = GLMapPoint()
        var selectedObjects: [GLMapVectorObject] = []
        for array in tapObjects {
            guard array.count > 0 else {continue}
            for i in 0...array.count - 1 {
                let object = array[i]
                if object.findNearestPoint(&nearestPoint, to: touchCoordinate, maxDistance: maxDist) && (object.type.rawValue == 1 || object.type.rawValue == 2) {
                    selectedObjects.append(object)
                }
            }
        }
        for object in selectedObjects {
            guard let id = object.getObjectID() else { continue }
            result.insert(id)
        }
        return result
    }
    
    //  Displays created and modified objects.
    func showSavedObjects() {
        let savedObjects = GLMapVectorObjectArray()
        let newObjects = GLMapVectorObjectArray()
        for (id, osmObject) in AppSettings.settings.savedObjects {
            let object = osmObject.getVectorObject()
            object.setValue(String(id), forKey: "@id")
            if id < 0 {
                newObjects.add(object)
            } else {
                savedObjects.add(object)
            }
            tapObjects.append(newObjects)
            tapObjects.append(savedObjects)
        }
        if let drawble = showedDrawable[10],
           let deleteClouser = deleteDrawbleClouser {
            deleteClouser(drawble)
        }
        if savedObjects.count > 0,
           let savedStyle = savedStyle,
           let addClouser = addDrawbleClouser  {
            let savedDrawable = GLMapVectorLayer(drawOrder: 1)
            savedDrawable.setVectorObjects(savedObjects, with: savedStyle, completion: nil)
            addClouser(savedDrawable)
        }
        if let drawble = showedDrawable[9],
           let deleteClouser = deleteDrawbleClouser {
            deleteClouser(drawble)
        }
        if newObjects.count > 0,
           let newStyle = newStyle,
           let addClouser = addDrawbleClouser {
            let newDrawble = GLMapVectorLayer(drawOrder: 2)
            newDrawble.setVectorObjects(newObjects, with: newStyle, completion: nil)
            addClouser(newDrawble)
        }
    }
    
}
