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
class MapViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
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
    // Variable activates the source data loading mode
    var isDownloadSource = false
    let indicator = UIActivityIndicatorView()
    let centerIcon = UIImageView()
    let addNodeButton = UIButton()
    
    //  Displays the object that was tapped and whose properties are currently being edited (yellow).
    var editDrawble = GLMapVectorLayer(drawOrder: 4)
    let editStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.editStyle)
    //  Highlights objects that fell under the tap, if there was not one object under the tap, but several.
    let tappedDrawble = GLMapVectorLayer(drawOrder: 3)
    let tappedStyle = GLMapVectorCascadeStyle.createStyle(AppSettings.settings.tappedStyle)
    
    override func viewDidLoad() {
        super.viewDidLoad()
//      Creating and adding MapView
        setMapView()
        
        mapClient.delegate = self
        
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
//        setTestButton()
//        setCenterMap()
        
//      Reading the modified and created objects into the AppSettings.settings.savedObjects variable.
        AppSettings.settings.getSavedObjects()
//      In the background, we start parsing the file with Josm presets.
        DispatchQueue.global(qos: .default).async {
            Parser().fillPresetElements()
            Parser().fillChunks()
        }
    }
    
    override func viewDidAppear(_: Bool) {
        // After successfully adding the map to the view, we set the initial position of the map
        setMapLocation()
        // After setting the starting position, all offsets are stored in memory. Clouser download source data while map did move.
        setDidMapMoveClouser()
        mapClient.showSavedObjects()
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
    }
    
    func setDidMapMoveClouser() {
        mapView.mapDidMoveBlock = { [weak self] _ in
            guard let self = self else { return }
            AppSettings.settings.lastBbox = self.mapView.bbox
            guard self.isDownloadSource == true else { return }
            let zoom = self.mapView.mapZoomLevel
            let beginLoadZoom = 15.0
            if zoom > beginLoadZoom {
                self.downloadButton.backgroundColor = .systemGreen
                self.checkMapCenter()
            } else {
                self.downloadButton.backgroundColor = .systemGray
            }
        }
    }
    
    func setDownloadButton() {
        downloadButton.layer.cornerRadius = 5
        downloadButton.isHighlighted = false
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
    
    func checkMapCenter() {
        Task {
            do {
                try await mapClient.checkMapCenter(center: mapView.mapGeoCenter)
            } catch {
                let message = "Error download data. Lat: \(mapView.mapGeoCenter.lat),lon: \(mapView.mapGeoCenter.lon), bbox size: \(mapClient.defaultBboxSize).\nError: \(error)"
                showAction(message: message, addAlerts: [])
            }
        }
    }
    
    @objc func tapDownloadButton() {
        print(isDownloadSource)
        isDownloadSource = !isDownloadSource
        if isDownloadSource {
            let zoom = mapView.mapZoomLevel
            let beginLoadZoom = 15.0
            if zoom > beginLoadZoom {
                downloadButton.backgroundColor = .systemGreen
                checkMapCenter()
            } else {
                downloadButton.backgroundColor = .systemGray
            }
        } else {
            downloadButton.backgroundColor = .white
        }
    }
    
    //  The indicator that appears in place of the data download button.
    func setLoadIndicator() {
        indicator.style = .large
        indicator.color = .black
        indicator.isUserInteractionEnabled = false
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
        navController?.dismissClosure = { [weak self] in
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
        let savedNodesButton = SavedObjectButton()
        mapClient.savedNodeButtonLink = savedNodesButton
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
        mapView.animate { [weak self] animation in
            guard let self = self else { return }
            animation.duration = 0.25
            animation.transition = .linear
            self.mapView.mapOrigin = CGPoint(x: 0.5, y: 0.75)
        }
        let savedNodesVC = SavedNodesViewController()
        savedNodesVC.delegate = self
        navController = NavigationController(rootViewController: savedNodesVC)
        navController?.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.navController = nil
            self.mapView.remove(self.editDrawble)
            self.mapView.animate { animation in
                animation.duration = 0.25
                animation.transition = .linear
                self.mapView.mapOrigin = CGPoint(x: 0.5, y: 0.5)
            }
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
        // To send the created objects to the server, you need to assign them an id < 0. To prevent duplicate IDs, the AppSettings.settings.nextId variable has been created, which reduces the id by 1 each time.
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
    
    @objc func tapTestButton() {
//        mapClient.pr()
    }
    
//    MARK: FUNCTIONS

    //  The method searches for vector objects under the tap. If 1 object is detected, it goes to the controller for editing its tags, if > 1, it offers to select an object from the tapped ones.
    @objc func getObjects(sender: UITapGestureRecognizer) {
//        if mapClient.objects.count == 0 { return }
        let touchPoint = sender.location(in: mapView)
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
            let centerPoint = mapView.makeGeoPoint(fromDisplay: touchPoint)
            mapView.animate { animation in
                animation.duration = 0.25
                animation.transition = .linear
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
        mapView.animate { [weak self] animation in
            guard let self = self else { return }
            animation.duration = 0.25
            animation.transition = .linear
            self.mapView.mapOrigin = CGPoint(x: 0.5, y: 0.75)
        }
        let selectVC = SelectObjectViewController(objects: objects)
        selectVC.delegate = self
        navController = NavigationController(rootViewController: selectVC)
        navController?.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.mapView.remove(self.tappedDrawble)
            self.mapView.remove(self.editDrawble)
            self.navController = nil
            self.mapView.animate { animation in
                animation.duration = 0.25
                animation.transition = .linear
                self.mapView.mapOrigin = CGPoint(x: 0.5, y: 0.5)
            }
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
        mapView.animate { [weak self] animation in
            guard let self = self else { return }
            animation.duration = 0.25
            animation.transition = .linear
            self.mapView.mapOrigin = CGPoint(x: 0.5, y: 0.75)
        }
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
            navController?.dismissClosure = { [weak self] in
                guard let self = self else { return }
                self.navController = nil
                self.mapView.remove(self.editDrawble)
                self.mapView.animate { animation in
                    animation.duration = 0.25
                    animation.transition = .linear
                    self.mapView.mapOrigin = CGPoint(x: 0.5, y: 0.5)
                }
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

extension MapViewController: MapClientProtocol {
    func addDrawble(layer: GLMapDrawable) {
        mapView.add(layer)
    }
    
    func removeDrawble(layer: GLMapDrawable) {
        mapView.remove(layer)
    }
    
    func startDownload() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setLoadIndicator()
        }
    }
    
    func endDownload() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.removeIndicator(indicator: self.indicator)
        }
    }
}

extension MapViewController: ShowTappedObject {
    //  The method displays the vector object passed to it and moves it to the visible part of the map. It is used on the tag editing controller, and on the object selection controller, if there are several of them under the tap.
    func showTapObject(object: GLMapVectorObject) {
        var newCenter = GLMapGeoPoint(lat: 1, lon: 1)
        switch object.type.rawValue {
        case 1:
            newCenter = GLMapGeoPoint(point: object.point)
        case 2:
            newCenter = GLMapGeoPoint(point: object.bbox.center)
        default:
            return
        }
        if let editStyle = editStyle {
            editDrawble.setVectorObject(object, with: editStyle, completion: nil)
        }
        mapView.add(editDrawble)
        mapView.animate { animation in
            animation.duration = 0.25
            animation.transition = .linear
            mapView.mapGeoCenter = newCenter
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
    
    //  The method updates the uploaded data. It is called from the tag editing controller and the saved objects display controller, after the changes have been successfully sent to the server.
    func updateSourceData() {
        setLoadIndicator()
        guard let lastCenter = mapClient.lastCenter else { return }
        Task {
            try await mapClient.getSourceBbox(mapCenter: lastCenter)
            removeIndicator(indicator: indicator)
        }
    }
}
