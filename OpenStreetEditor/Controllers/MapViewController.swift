//
//  ViewController.swift
//  OSM editor
//
//  Created by Аркадий Торвальдс on 04.08.2022.
//

import GLMap
import GLMapCore
import SwiftUI
import UIKit
import XMLCoder

//  RootViewController with mapView
class MapViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate, ShowTappedObject {
    //  Class for working with MapView. Subsequently, all GLMap entities should be transferred to it.
    let mapClient = MapClient()
    //  map and location service
    var mapView: GLMapView!
    private let locationManager = CLLocationManager()
    
    //  The variable in which the reference to the open UINavigationController is stored. When initializing any controller, there is a check for nil, for example, in the goToSAvedNodesVC() method.
    var navController: NavigationController?
    
    //  Simple tap
    var oneTap = UIGestureRecognizer()
    
    //  Buttons
    let downloadButton = UIButton()
    let indicator = UIActivityIndicatorView()
    let centerIcon = UIImageView()
    let addNodeButton = UIButton()
    let savedNodesButton = SavedObjectButton()

    //  Drawble objects and styles to display data on MapView.
    var sourceDrawable = GLMapVectorLayer(drawOrder: 0)
    let sourceStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.defaultStyle)
    //  Displays objects that have been modified but not sent to the server (green).
    var savedDrawable = GLMapVectorLayer(drawOrder: 1)
    let savedStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.savedStyle)
    //  Displays the object that was tapped and whose properties are currently being edited (yellow).
    var editDrawble = GLMapVectorLayer(drawOrder: 4)
    let editStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.editStyle)
    //  Displays objects created but not sent to the server (orange color).
    let newDrawble = GLMapVectorLayer(drawOrder: 2)
    let newStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.newStyle)
    //  Highlights objects that fell under the tap, if there was not one object under the tap, but several.
    let tappedDrawble = GLMapVectorLayer(drawOrder: 3)
    let tappedStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.tappedStyle)
    
    override func viewDidLoad() {
        super.viewDidLoad()
//      Creating and adding MapView
        setMapView()
        
//      Every time AppSettings.settings.savedObjects is changed (this is the variable in which the modified or created objects are stored), a closure is called. In this case, when a short circuit is triggered, we update the illumination of saved and created objects.
        AppSettings.settings.mapVCClouser = { [weak self] in
            guard let self = self else { return }
            self.showSavedObjects()
        }
        
//      We run the definition of the geo position and check its resolution for the application in the settings.
        locationManager.startUpdatingLocation()
        chekAuthorization()
        
//      Setting up taps.
        let doubleTap = UITapGestureRecognizer(target: self, action: nil)
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
        let oneTap = UITapGestureRecognizer(target: self, action: #selector(getObjects))
        oneTap.numberOfTapsRequired = 1
        oneTap.delegate = self
        oneTap.require(toFail: doubleTap)
        mapView.addGestureRecognizer(oneTap)
        let pressTap = UILongPressGestureRecognizer(target: self, action: #selector(createPoint))
        pressTap.minimumPressDuration = 0.5
        oneTap.require(toFail: pressTap)
        pressTap.delegate = self
        mapView.addGestureRecognizer(pressTap)
        
//      Add buttons
        setDownloadButton()
        setupSettingsButton()
        setupLocationButton()
        setSavedNodesButton()
//      The test button in the lower right corner of the screen is often needed during development.
        setTestButton()
        
//      Reading the modified and created objects into the AppSettings.settings.savedObjects variable.
        AppSettings.settings.getSavedObjects()
//      Displays created and modified objects.
        showSavedObjects()
//      In the background, we start parsing the file with Josm presets.
        DispatchQueue.global(qos: .default).async {
            Parser().fillPresetElements()
            Parser().fillChunks()
        }
    }
    
    override func viewDidAppear(_: Bool) {
//      After successfully adding the map to the view, we set the initial position of the map
        setMapLocation()
    }
    
//        MARK: ELEMENTS AND ACTIONS
    
    func setMapView() {
        mapView = GLMapView()
        mapView.showUserLocation = true
        var locationImage: UIImage?
        if let locationImagePath = Bundle.main.path(forResource: "circle_location", ofType: "svg") {
            locationImage = GLMapVectorImageFactory.shared.image(fromSvg: locationImagePath)
        } else {
            locationImage = UIImage(systemName: "circle.fill")
        }
        mapView.setUserLocationImage(locationImage, movementImage: nil)
//      We specify that the map titles are always loaded.
        GLMapManager.shared.tileDownloadingAllowed = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
    }
    
    //  Set the initial position of the map
    func setMapLocation() {
        if let bbox = AppSettings.settings.lastBbox {
            mapView.mapCenter = bbox.center
            mapView.mapZoom = mapView.mapZoom(for: bbox)
        } else {
            if let location = locationManager.location {
                mapView.mapGeoCenter = GLMapGeoPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                mapView.mapZoomLevel = 15
            } else {
                mapView.mapGeoCenter = GLMapGeoPoint(lat: 52.5212, lon: 13.4057)
                mapView.mapZoomLevel = 10
            }
        }
//      After setting the starting position, all offsets are stored in memory
        mapView.mapDidMoveBlock = { [weak self] _ in
            guard let self = self else { return }
            print(self.mapView.mapZoomLevel)
            AppSettings.settings.lastBbox = self.mapView.bbox
        }
    }

    func setDownloadButton() {
        downloadButton.layer.cornerRadius = 5
        downloadButton.backgroundColor = .white
        downloadButton.setImage(UIImage(systemName: "square.and.arrow.down.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        downloadButton.addTarget(self, action: #selector(tapDownloadButton), for: .touchUpInside)
        view.addSubview(downloadButton)
        
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([downloadButton.widthAnchor.constraint(equalToConstant: 45),
                                     downloadButton.heightAnchor.constraint(equalToConstant: 45),
                                     downloadButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
                                     downloadButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10)])
    }
    
    @objc func tapDownloadButton() {
        // English: We get the coordinates of the corners of the screen, save them in an array and take the minimum and maximum values. These are the parameters of the bbox data to download
        let point1 = mapView.makeGeoPoint(fromDisplay: CGPoint(x: 0, y: UIScreen.main.bounds.height))
        let point2 = mapView.makeGeoPoint(fromDisplay: CGPoint(x: UIScreen.main.bounds.width, y: UIScreen.main.bounds.height))
        let point3 = mapView.makeGeoPoint(fromDisplay: CGPoint(x: UIScreen.main.bounds.width, y: 0))
        let point4 = mapView.makeGeoPoint(fromDisplay: CGPoint(x: 0, y: 0))
        let latitudeArray: [Double] = [point1.lat, point2.lat, point3.lat, point4.lat]
        let longitudeArray: [Double] = [point1.lon, point2.lon, point3.lon, point4.lon]
        guard let latitudeDisplayMin = latitudeArray.min(),
              let latitudeDisplayMax = latitudeArray.max(),
              let longitudeDisplayMin = longitudeArray.min(),
              let longitudeDisplayMax = longitudeArray.max()
        else {
            let message = "Error get display coordinate: \(point1.lat), \(point1.lon); \(point2.lat), \(point2.lon); \(point3.lat), \(point3.lon); \(point4.lat), \(point4.lon). Try rotate the map"
            showAction(message: message, addAlerts: [])
            return
        }
//      0.007 and 0.025 are experimentally selected values of the maximum size of the bbox of map. If you do the above, with a high density of points, the application slows down and the OSM server may not allow you to download data.
        if latitudeDisplayMax - latitudeDisplayMin < 0.007 && longitudeDisplayMax - longitudeDisplayMin < 0.025 {
            setLoadIndicator()
            Task {
                do {
//                  We download the data from the server, convert it to GeoJSON and write it to files.
                    try await mapClient.getSourceData(longitudeDisplayMin: longitudeDisplayMin, latitudeDisplayMin: latitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax, latitudeDisplayMax: latitudeDisplayMax)
//                  Displaying data on the map.
                    showGeoJSON()
                    showSavedObjects()
                    Task {
//                      In the background, we start indexing the downloaded data and saving them with the dictionary appSettings.settings.inputObjects for quick access to the object by its id.
                        await getNodesFromXML()
                    }
                } catch {
                    let message = error as? String ?? "Unknown error"
                    showAction(message: message, addAlerts: [])
                    removeIndicator(indicator: indicator)
                }
            }
        } else {
//          If the zoom scale is too small, to prevent downloading too much data, do not download them.
            showAction(message: "The editing area is too large. Zoom in.", addAlerts: [])
        }
    }
    
    //  The indicator that appears in place of the data download button.
    func setLoadIndicator() {
        indicator.style = .large
        indicator.layer.cornerRadius = 5
        indicator.backgroundColor = .systemBackground
        indicator.startAnimating()
        view.addSubview(indicator)
        
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([indicator.widthAnchor.constraint(equalToConstant: 45),
                                     indicator.heightAnchor.constraint(equalToConstant: 45),
                                     indicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
                                     indicator.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10)])
    }
        
    func setupSettingsButton() {
        let settingsButton = UIButton()
        settingsButton.layer.cornerRadius = 5
        settingsButton.backgroundColor = .white
        settingsButton.setImage(UIImage(systemName: "gearshape")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        settingsButton.addTarget(self, action: #selector(tapSettingsButton), for: .touchUpInside)
        view.addSubview(settingsButton)
        
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([settingsButton.widthAnchor.constraint(equalToConstant: 45),
                                     settingsButton.heightAnchor.constraint(equalToConstant: 45),
                                     settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 95),
                                     settingsButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10)])
    }
    
    @objc func tapSettingsButton() {
        if navController != nil {
            navController?.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.goToSettingsVC()
            }
        } else {
            goToSettingsVC()
        }
    }
    
    func goToSettingsVC() {
        let vc = MainViewController()
        navController = NavigationController(rootViewController: vc)
        navController?.callbackClosure = { [weak self] in
            guard let self = self else { return }
            self.navController = nil
        }
        if navController != nil {
            present(navController!, animated: true)
        }
    }
    
    func setupLocationButton() {
        let locationButton = UIButton()
        locationButton.layer.cornerRadius = 5
        locationButton.backgroundColor = .white
        locationButton.setImage(UIImage(systemName: "location.north.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        locationButton.addTarget(self, action: #selector(mapToLocation), for: .touchUpInside)
        view.addSubview(locationButton)
        
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([locationButton.widthAnchor.constraint(equalToConstant: 45),
                                     locationButton.heightAnchor.constraint(equalToConstant: 45),
                                     locationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 160),
                                     locationButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10)])
    }
    
    //  Moves the center of the map to the geo position.
    @objc func mapToLocation() {
        if let location = locationManager.location {
            mapView.animate { animation in
                animation.fly(to: GLMapPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude))
            }
        }
    }
    
    //  The button for switching to the controller with created and modified objects.
    func setSavedNodesButton() {
        savedNodesButton.layer.cornerRadius = 5
        savedNodesButton.backgroundColor = .white
        savedNodesButton.setImage(UIImage(systemName: "square.and.arrow.up.fill"), for: .normal)
        savedNodesButton.tintColor = .black
        savedNodesButton.addTarget(self, action: #selector(tapSavedNodesButton), for: .touchUpInside)
        view.addSubview(savedNodesButton)
        savedNodesButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([savedNodesButton.widthAnchor.constraint(equalToConstant: 45),
                                     savedNodesButton.heightAnchor.constraint(equalToConstant: 45),
                                     savedNodesButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 225),
                                     savedNodesButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10)])
    }
    
    @objc func tapSavedNodesButton() {
        if navController != nil {
            navController?.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.goToSAvedNodesVC()
            }
        } else {
            goToSAvedNodesVC()
        }
    }
    
    func goToSAvedNodesVC() {
        let savedNodesVC = SavedNodesViewController()
        savedNodesVC.delegate = self
        navController = NavigationController(rootViewController: savedNodesVC)
        navController?.callbackClosure = { [weak self] in
            guard let self = self else { return }
            self.navController = nil
            self.mapView.remove(self.editDrawble)
        }
        if let sheetPresentationController = navController?.presentationController as? UISheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
            sheetPresentationController.largestUndimmedDetentIdentifier = .medium
        }
        if navController != nil {
            present(navController!, animated: true, completion: nil)
        }
    }
    
    //  A red cross that appears when creating a new point (to clarify the position of the point).
    func setCenterMap() {
        centerIcon.image = UIImage(systemName: "plus")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        view.addSubview(centerIcon)
        centerIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([centerIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     centerIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }
    
    func setAddNodeButton() {
        addNodeButton.layer.cornerRadius = 5
        addNodeButton.backgroundColor = .green
        addNodeButton.setImage(UIImage(named: "addnode"), for: .normal)
        addNodeButton.addTarget(self, action: #selector(tapAddNodeButton), for: .touchUpInside)
        view.addSubview(addNodeButton)
        addNodeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([addNodeButton.widthAnchor.constraint(equalToConstant: 45),
                                     addNodeButton.heightAnchor.constraint(equalToConstant: 45),
                                     addNodeButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10),
                                     addNodeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 225)])
    }
    
    @objc func tapAddNodeButton() {
        centerIcon.removeFromSuperview()
        addNodeButton.removeFromSuperview()
        let geoPoint = mapView.makeGeoPoint(fromDisplay: mapView.center)
//      To send the created objects to the server, you need to assign them an id < 0. To prevent duplicate IDs, the AppSettings.settings.nextId variable has been created, which reduces the id by 1 each time.
        let object = OSMAnyObject(type: .node, id: AppSettings.settings.nextID, version: 0, changeset: 0, lat: geoPoint.lat, lon: geoPoint.lon, tag: [], nd: [], nodes: [:])
        goToPropertiesVC(object: object)
    }
    
    //  Test button and its target for debugging convenience.
    func setTestButton() {
        let testButton = UIButton()
        testButton.layer.cornerRadius = 5
        testButton.backgroundColor = .white
        testButton.setImage(UIImage(systemName: "pencil")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        testButton.addTarget(self, action: #selector(tapTestButton), for: .touchUpInside)
        view.addSubview(testButton)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([testButton.widthAnchor.constraint(equalToConstant: 45),
                                     testButton.heightAnchor.constraint(equalToConstant: 45),
                                     testButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10),
                                     testButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)])
    }
    
    @objc func tapTestButton() {}
    
//    MARK: FUNCTIONS

    //  The method searches for vector objects under the tap. If 1 object is detected, it goes to the controller for editing its tags, if > 1, it offers to select an object from the tapped ones.
    @objc func getObjects(sender: UITapGestureRecognizer) {
        if mapClient.objects.count == 0 { return }
        var touchPoint = sender.location(in: mapView)
        let touchPointMapCoordinate = mapView.makeMapPoint(fromDisplay: touchPoint)
        let maxTapDistance = 20
        let tmp = mapView.makeMapPoint(fromDisplayDelta: CGPoint(x: maxTapDistance, y: 0))
        let tapObjects = mapClient.openObject(touchCoordinate: touchPointMapCoordinate, tmp: tmp)
        switch tapObjects.count {
        case 0:
            return
        case 1:
            if let first = tapObjects.first {
                openObject(id: first)
            }
        default:
//          Moves the tapped object to the visible part of the map.
            touchPoint.y += view.frame.height / 4
            let centerPoint = mapView.makeGeoPoint(fromDisplay: touchPoint)
            mapView.animate { animation in
                animation.fly(to: centerPoint)
            }
            var objects: [OSMAnyObject] = []
//          If some objects cannot be opened, then it will indicate their id.
            var failObjects: [Int] = []
            for id in tapObjects {
                if let object = AppSettings.settings.savedObjects[id] {
                    objects.append(object)
                } else if let osmObject = AppSettings.settings.inputObjects[id] {
                    guard let object = convertOSMToObject(osmObject: osmObject) else {
                        failObjects.append(id)
                        continue
                    }
                    objects.append(object)
                }
            }
            if tapObjects.count != objects.count {
                let alert = UIAlertAction(title: "Continue", style: .default, handler: { _ in
                    self.selectObjects(objects: objects)
                })
                showAction(message: "Objects with the listed IDs cannot be opened: \(failObjects)", addAlerts: [alert])
            } else {
                selectObjects(objects: objects)
            }
        }
    }
    
    //  Calls the object selection controller if there are several of them under the tap.
    func selectObjects(objects: [OSMAnyObject]) {
        if navController != nil {
            navController?.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.goToSelectVC(objects: objects)
            }
        } else {
            goToSelectVC(objects: objects)
        }
    }
    
    func goToSelectVC(objects: [OSMAnyObject]) {
        let selectVC = SelectObjectViewController(objects: objects)
        selectVC.delegate = self
        navController = NavigationController(rootViewController: selectVC)
        navController?.callbackClosure = { [weak self] in
            guard let self = self else { return }
            self.mapView.remove(self.tappedDrawble)
            self.mapView.remove(self.editDrawble)
            self.navController = nil
        }
        if let sheetPresentationController = navController?.presentationController as? UISheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
            sheetPresentationController.largestUndimmedDetentIdentifier = .medium
        }
        if navController != nil {
            present(navController!, animated: true, completion: nil)
        }
    }
    
    //  If there are no objects under the tap, they are highlighted by this method.
    func showTappedObjects(objects: [OSMAnyObject]) {
        mapView.remove(editDrawble)
        let tappedObjects = GLMapVectorObjectArray()
        for object in objects {
            let vector = object.getVectorObject()
            tappedObjects.add(vector)
        }
        if let style = tappedStyle {
            tappedDrawble.setVectorObjects(tappedObjects, with: style, completion: nil)
        }
        mapView.add(tappedDrawble)
    }
    
    //  Objects that are detected under the tap can be stored both in appSettings.settings.inputObjects (downloaded from the server) and in appSettings.settings.savedObjects (created or modified earlier). The method determines where the object is stored, and passes it to the tag editing controller.
    func openObject(id: Int) {
        if let object = AppSettings.settings.savedObjects[id] {
            goToPropertiesVC(object: object)
        } else if let osmObject = AppSettings.settings.inputObjects[id] as? Node {
            guard let object = convertOSMToObject(osmObject: osmObject) else {
                showAction(message: "Error converting node to OSMAnyObject. ID: \(id)", addAlerts: [])
                return
            }
            goToPropertiesVC(object: object)
        } else if let osmObject = AppSettings.settings.inputObjects[id] as? Way {
            guard let object = convertOSMToObject(osmObject: osmObject) else {
                showAction(message: "Error converting way to OSMAnyObject. ID: \(id)", addAlerts: [])
                return
            }
            goToPropertiesVC(object: object)
        } else {
            showAction(message: "Object opening error, id: \(id)", addAlerts: [])
        }
    }
    
    //  The method opens the tag editing controller.
    //  The user can tap on the object on the visible part of the map at the moment when the editing controller is already open. Then the editable object on the controller changes to a new one.
    func goToPropertiesVC(object: OSMAnyObject) {
        let vector = object.getVectorObject()
        showTapObject(object: vector)
        if navController != nil {
            if let controllers = navController?.viewControllers {
                for controller in controllers where controller is InfoObjectViewController {
                    if let newInfoVC = controller as? InfoObjectViewController {
                        AppSettings.settings.saveAllowed = false
                        AppSettings.settings.newProperties = [:]
                        for tag in object.tag {
                            AppSettings.settings.newProperties[tag.k] = tag.v
                        }
                        newInfoVC.object = object
                        newInfoVC.fillData()
                        newInfoVC.tableView.reloadData()
                    }
                }
                for controller in controllers where controller is EditObjectViewController {
                    if let newEditVC = controller as? EditObjectViewController {
                        AppSettings.settings.saveAllowed = false
                        newEditVC.object = object
                        newEditVC.fillNewProperties()
                        newEditVC.fillData()
                        AppSettings.settings.saveAllowed = true
                        newEditVC.tableView.reloadData()
                        return
                    }
                }
            }
            let editVC = EditObjectViewController(object: object)
            navController?.pushViewController(editVC, animated: true)
        } else {
            let editVC = EditObjectViewController(object: object)
            navController = NavigationController(rootViewController: editVC)
//          When the user closes the tag editing controller, the backlight of the tapped object is removed.
            navController?.callbackClosure = { [weak self] in
                guard let self = self else { return }
                self.navController = nil
                self.mapView.remove(self.editDrawble)
            }
            if let sheetPresentationController = navController?.presentationController as? UISheetPresentationController {
                sheetPresentationController.detents = [.medium(), .large()]
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
                sheetPresentationController.largestUndimmedDetentIdentifier = .medium
            }
            if navController != nil {
                present(navController!, animated: true, completion: nil)
            }
        }
    }
        
    //  The method of creating a new point by a long tap.
    @objc func createPoint(sender: UILongPressGestureRecognizer) {
        if sender.state.rawValue == 1 {
            sender.state = .ended
            let location = sender.location(in: mapView)
            let newMapCenter = mapView.makeGeoPoint(fromDisplay: CGPoint(x: location.x, y: location.y))
            mapView.animate { animation in
                animation.fly(to: newMapCenter)
            }
            setAddNodeButton()
            setCenterMap()
        }
    }

    //  The method displays the data downloaded from the server, which has been transcoded by osmium into a GeoJSON file.
    func showGeoJSON() {
        do {
            let dataGeojson = try Data(contentsOf: AppSettings.settings.outputFileURL)
            mapClient.objects = try GLMapVectorObject.createVectorObjects(fromGeoJSONData: dataGeojson)
            if let style = sourceStyle {
                sourceDrawable.setVectorObjects(mapClient.objects, with: style, completion: nil)
            }
            mapView.add(sourceDrawable)
        } catch {
            showAction(message: "Error show objects: \(error)", addAlerts: [])
        }
    }
    
    //  Displays created and modified objects.
    func showSavedObjects() {
        mapView.remove(savedDrawable)
        mapView.remove(newDrawble)
        updateSavedNodesButton()
        guard AppSettings.settings.savedObjects.count > 0 else { return }
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
            mapClient.objects.add(object)
        }
        if let savedStyle = savedStyle {
            savedDrawable.setVectorObjects(savedObjects, with: savedStyle, completion: nil)
        }
        if let newStyle = newStyle {
            newDrawble.setVectorObjects(newObjects, with: newStyle, completion: nil)
        }
        mapView.add(savedDrawable)
        mapView.add(newDrawble)
    }
    
    //  The method updates the transition button to the controller of saved and modified objects (adds and removes the green circle).
    func updateSavedNodesButton() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.savedNodesButton.update()
        }
    }
    
    //  In the background, we start indexing the downloaded data and saving them with the dictionary appSettings.settings.inputObjects for quick access to the object by its id.
    func getNodesFromXML() async {
        do {
            let data = try Data(contentsOf: AppSettings.settings.inputFileURL)
            let xmlObjects = try XMLDecoder().decode(osm.self, from: data)
            for node in xmlObjects.node {
                AppSettings.settings.inputObjects[node.id] = node
            }
            for way in xmlObjects.way {
                AppSettings.settings.inputObjects[way.id] = way
            }
            removeIndicator(indicator: indicator)
        } catch {
            removeIndicator(indicator: indicator)
            showAction(message: "Data indexing error: \(error)", addAlerts: [])
        }
    }
    
    //  The method displays the vector object passed to it and moves it to the visible part of the map. It is used on the tag editing controller, and on the object selection controller, if there are several of them under the tap.
    func showTapObject(object: GLMapVectorObject) {
        var glPoint = GLMapPoint(lat: 1, lon: 1)
        var newCenter = GLMapGeoPoint(lat: 1, lon: 1)
        switch object.type.rawValue {
        case 1:
            glPoint = object.point
            var displayPoint = mapView.makeDisplayPoint(from: glPoint)
            displayPoint.y += CGFloat(view.frame.height / 4)
            newCenter = mapView.makeGeoPoint(fromDisplay: displayPoint)
        case 2:
            glPoint = object.bbox.center
            var displayPoint = mapView.makeDisplayPoint(from: glPoint)
            displayPoint.y += CGFloat(view.frame.height / 4)
            newCenter = mapView.makeGeoPoint(fromDisplay: displayPoint)
        default:
            return
        }
        if let editStyle = editStyle {
            editDrawble.setVectorObject(object, with: editStyle, completion: nil)
        }
        mapView.add(editDrawble)
        mapView.animate { _ in
            mapView.mapGeoCenter = newCenter
        }
    }

    //  The method updates the uploaded data. It is called from the tag editing controller and the saved objects display controller, after the changes have been successfully sent to the server.
    func updateSourceData() {
        if mapClient.objects.count == 0 {
            return
        }
        guard let longitudeDisplayMin = OsmClient.client.lastLongitudeDisplayMin,
              let latitudeDisplayMin = OsmClient.client.lastLatitudeDisplayMin,
              let longitudeDisplayMax = OsmClient.client.lasltLongitudeDisplayMax,
              let latitudeDisplayMax = OsmClient.client.lastLatitudeDisplayMax else { return }
        Task {
            setLoadIndicator()
            do {
                try await mapClient.getSourceData(longitudeDisplayMin: longitudeDisplayMin, latitudeDisplayMin: latitudeDisplayMin, longitudeDisplayMax: longitudeDisplayMax, latitudeDisplayMax: latitudeDisplayMax)
                showGeoJSON()
                showSavedObjects()
                Task {
                    await getNodesFromXML()
                }
            } catch {
                let message = error as? String ?? "Unknown error"
                showAction(message: message, addAlerts: [])
            }
        }
    }
    
    func setupManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
        
    func checkLocationEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            setupManager()
            chekAuthorization()
        } else {
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: "App-Prefs:root=LOCATION_SERVICES") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            showAction(message: "Geolocation is turned off. Turn on?", addAlerts: [settingsAction, cancelAction])
        }
    }
        
    func chekAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied:
            showAction(message: "Geolocation is prohibited", addAlerts: [])
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool { return true }
}
