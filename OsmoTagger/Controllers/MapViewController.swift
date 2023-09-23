//
//  ViewController.swift
//  OSM editor
//
//  Created by Аркадий Торвальдс on 04.08.2022.
//

import GLMap
import GLMapCore
import UIKit

//  RootViewController with mapView
class MapViewController: UIViewController {
    
    //  Class for working with MapView. Subsequently, all GLMap entities should be transferred to it.
    let mapClient = MapClient()
    let screenManager = ScreenManager()
    
    //  map and location service
    var mapView: GLMapView!
    var mapViewTrailingAnchor = NSLayoutConstraint()
    
    private let locationManager = CLLocationManager()
    
    //  The variable in which the reference to the open UINavigationController is stored. When initializing any controller, there is a check for nil, for example, in the goToSAvedNodesVC() method.
    var navController: SheetNavigationController?
    
    // plus zoom, minus zoom, map angle
    let mapZoomButtons = MapZoomButtonsView()
    
    //  Buttons
    let downloadButton = MapButton()
    let indicator = DownloadIndicatorView()
    let centerIcon = UIImageView()
    let addNodeButton = MapButton()
    var addNodeButtonTopConstraint = NSLayoutConstraint()
    
    //  Displays the object that was tapped and whose properties are currently being edited (yellow).
    var editDrawble = GLMapVectorLayer(drawOrder: 4)
    
    private let animationDuration = 0.3
    
    override var keyCommands: [UIKeyCommand]? {
        #if targetEnvironment(macCatalyst)
        let left = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(moveLeft))
        left.wantsPriorityOverSystemBehavior = true
        let right = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(moveRight))
        right.wantsPriorityOverSystemBehavior = true
        let up = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(moveUp))
        up.wantsPriorityOverSystemBehavior = true
        let down = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(moveDown))
        down.wantsPriorityOverSystemBehavior = true
        return [
            UIKeyCommand(input: "=", modifierFlags: [], action: #selector(tapPlusButton)),
            UIKeyCommand(input: "-", modifierFlags: [], action: #selector(tapMinusButton)),
            left, right, up, down ]
        #else
        return nil
        #endif
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Creating and adding MapView
        setMapView()
        
        mapClient.delegate = self
        
        setScreenManagerClosures()
        
        // We run the definition of the geo position and check its resolution for the application in the settings.
        locationManager.startUpdatingLocation()
        chekAuthorization()
        
        // Setting up taps.
        let doubleTap = UITapGestureRecognizer(target: self, action: nil)
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
        let oneTap = UITapGestureRecognizer(target: self, action: #selector(getObjects))
        oneTap.numberOfTapsRequired = 1
        oneTap.delegate = self
        oneTap.require(toFail: doubleTap)
        mapView.addGestureRecognizer(oneTap)
        
        // Add system buttons
        setLoadIndicator()
        setDownloadButton()
        setupSettingsButton()
        setupLocationButton()
        setSavedNodesButton()
        setAddNodeButton()
        setDrawButton()
        // The test button in the lower right corner of the screen is often needed during development.
         setTestButton()
        
        // Zoom in and zoom out buttons, map rotation button
        setMapZoomButtons()
    }
    
    override func viewDidAppear(_: Bool) {
        // After successfully adding the map to the view, we set the initial position of the map
        setMapLocation()
        // After setting the starting position, all offsets are stored in memory. Clouser download source data while map did move.
        setDidMapMoveClouser()
        // After configuring the map, we enable/disable the addNodeButton depending on the zoom level.
        updateAddNodeButton()
        // To highlight the edited object, the vector object is written to singleton appSettings, on which the closure is triggered.
        // When this closure is called, the object is added to the map and the zoom is adjusted
        setShowVectorObjectClosure()
        mapClient.showSavedObjects()
        #if targetEnvironment(macCatalyst)
        Alert.showAlert("Use the \"left,\" \"right,\" \"down,\" \"up,\" \"+,\" and \"-\" keys for navigation", isBad: false)
        #endif
    }
    
    private func setScreenManagerClosures() {
        screenManager.moveUpClosure = { [weak self] in
            guard let self = self else { return }
            self.runOpenAnimation()
        }
        screenManager.moveDownClosure = { [weak self] in
            guard let self = self else { return }
            self.runCloseAnimation()
        }
        screenManager.moveRightClosure = { [weak self] in
            guard let self = self else { return }
            self.mapViewTrailingAnchor.constant = 0
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.view.layoutIfNeeded()
            })
        }
        screenManager.moveLeftClosure = { [weak self] in
            guard let self = self else { return }
            self.mapViewTrailingAnchor.constant = -self.screenManager.childWidth
        }
        screenManager.removeTappedObjectsClosure = { [weak self] in
            guard let self = self else {return}
            self.mapView.remove(self.mapClient.tappedDrawble)
        }
    }
    
    // MARK: MapView and layers
    
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
        // We specify that the map titles are always loaded.
        GLMapManager.shared.tileDownloadingAllowed = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        mapViewTrailingAnchor = NSLayoutConstraint(item: mapView!, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapViewTrailingAnchor,
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        ])
    }
    
    //  Set the initial position of the map
    func setMapLocation() {
        // Uncomment when you need to take screenshots. This is the Statue of Liberty in New York.
        // Set your location in ios simulator to lat: 40,690825, lon: -74,045662
        // comment the code block with if-else
        // mapView.mapGeoCenter = GLMapGeoPoint(lat: 40.689739905669796, lon: -74.04507003627924)
        // mapView.mapAngle = 145.5305633544922
        // mapView.mapZoomLevel = 17.43877570923042
        // AppSettings.settings.mapButtonsIsHidden = true
        // AppSettings.settings.isDevServer = true
        if let bbox = AppSettings.settings.lastBbox {
            mapView.mapCenter = bbox.center
            mapView.mapZoom = mapView.mapZoom(for: bbox)
        } else if let location = locationManager.location {
            mapView.mapGeoCenter = GLMapGeoPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            mapView.mapZoomLevel = 15
        }
    }
    
    func setDidMapMoveClouser() {
        mapView.mapDidMoveBlock = { [weak self] _ in
            guard let self = self else { return }
            // rotate mapButtons.angleButton image
            let angle = CGFloat(self.mapView.mapAngle)
            let radian = angle * .pi / 180
            mapZoomButtons.angleButton.image.transform = CGAffineTransform(rotationAngle: -radian)
            
            if self.navController == nil {
                AppSettings.settings.lastBbox = self.mapView.bbox
            }
            let zoom = self.mapView.mapZoomLevel
            let beginLoadZoom = 16.0
            self.addNodeButton.alpha = zoom > beginLoadZoom ? 1 : 0.5
        }
    }
    
    func setShowVectorObjectClosure() {
        AppSettings.settings.showVectorObjectClosure = { [weak self] vectorObject in
            guard let self = self else { return }
            if let object = vectorObject {
                self.editDrawble.setVectorObject(object, with: MapStyles.editStyle, completion: nil)
                self.mapView.add(self.editDrawble)
                let newCenter = GLMapGeoPoint(point: object.bbox.center)
                let userZoom = self.mapView.mapZoom
                var viewSize = self.view.bounds.size
                // Visible part of the screen
                viewSize.width = viewSize.width * 0.98
                viewSize.height = viewSize.height / 2.2
                var objectZoom = self.mapView.mapZoom(for: object.bbox, viewSize: viewSize)
                if objectZoom > userZoom {
                    objectZoom = userZoom
                }
                self.mapView.animate { [weak self] animation in
                    guard let self = self else { return }
                    animation.duration = self.animationDuration
                    animation.transition = .linear
                    self.mapView.mapGeoCenter = newCenter
                    self.mapView.mapZoom = objectZoom
                }
            } else {
                self.mapView.remove(self.editDrawble)
            }
        }
    }
    
    private func runOpenAnimation() {
        mapView.animate { [weak self] animation in
            guard let self = self else { return }
            animation.duration = 0.3
            animation.transition = .linear
            self.mapView.mapOrigin = CGPoint(x: 0.5, y: 0.75)
        }
    }
    
    private func runCloseAnimation() {
        mapView.animate { [weak self] animation in
            guard let self = self else { return }
            animation.duration = self.animationDuration
            animation.transition = .linear
            self.mapView.mapOrigin = CGPoint(x: 0.5, y: 0.5)
        }
    }
    
    // MARK: Set screen elements

    // Zoom in and zoom out buttons, map rotation button
    func setMapZoomButtons() {
        mapZoomButtons.plusButton.addTarget(self, action: #selector(tapPlusButton), for: .touchUpInside)
        mapZoomButtons.minusButton.addTarget(self, action: #selector(tapMinusButton), for: .touchUpInside)
        let angleTap = UITapGestureRecognizer()
        angleTap.delegate = self
        angleTap.addTarget(self, action: #selector(tapAngleButton))
        mapZoomButtons.angleButton.addGestureRecognizer(angleTap)
        view.addSubview(mapZoomButtons)
        NSLayoutConstraint.activate([
            mapZoomButtons.heightAnchor.constraint(equalToConstant: 150),
            mapZoomButtons.widthAnchor.constraint(equalToConstant: 40),
            mapZoomButtons.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            mapZoomButtons.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 300),
        ])
    }
    
    @objc func tapPlusButton() {
        mapView.animate { [weak self] animation in
            guard let self = self else { return }
            animation.duration = animationDuration
            self.mapView.mapZoomLevel += 1
        }
    }
    
    @objc func tapMinusButton() {
        mapView.animate { [weak self] animation in
            guard let self = self else { return }
            animation.duration = animationDuration
            self.mapView.mapZoomLevel -= 1
        }
    }
    
    @objc func tapAngleButton() {
        mapView.animate { [weak self] animation in
            guard let self = self else { return }
            animation.duration = animationDuration
            self.mapView.mapAngle = 0
        }
    }
    
    @objc private func moveLeft() {
        moveMap(CGPoint(x: 40, y: 0))
    }
    
    @objc private func moveRight() {
        moveMap(CGPoint(x: -40, y: 0))
    }
    
    @objc private func moveUp() {
        moveMap(CGPoint(x: 0, y: 40))
    }
    
    @objc private func moveDown() {
        moveMap(CGPoint(x: 0, y: -40))
    }
    
    private func moveMap(_ delta: CGPoint) {
        var center = mapView.makeDisplayPoint(from: mapView.mapCenter)
        center.x -= delta.x
        center.y -= delta.y
        mapView.animate { anim in
            anim.transition = .easeOut
            mapView.mapCenter = mapView.makeMapPoint(fromDisplay: center)
        }
    }
    
    // The indicator that appears in place of the data download button.
    func setLoadIndicator() {
        indicator.isUserInteractionEnabled = false
        indicator.stopAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.widthAnchor.constraint(equalToConstant: 20),
            indicator.heightAnchor.constraint(equalToConstant: 20),
            indicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            indicator.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20)
        ])
    }
    
    func setDownloadButton() {
        downloadButton.configure(image: "square.and.arrow.down.fill")
        downloadButton.addTarget(self, action: #selector(tapDownloadButton), for: .touchUpInside)
        view.addSubview(downloadButton)
        NSLayoutConstraint.activate([
             downloadButton.widthAnchor.constraint(equalToConstant: 40),
             downloadButton.heightAnchor.constraint(equalToConstant: 40),
             downloadButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
             downloadButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20)
        ])
    }
    
    @objc func tapDownloadButton() {
        Task {
            do {
                try await mapClient.getSourceBbox(mapCenter: mapView.mapGeoCenter)
            } catch {
                let message = error as? String ?? "Error load data"
                Alert.showAlert(message)
            }
        }
    }
    
    func setupSettingsButton() {
        let settingsButton = MapButton()
        settingsButton.configure(image: "gearshape")
        settingsButton.addTarget(self, action: #selector(tapSettingsButton), for: .touchUpInside)
        view.addSubview(settingsButton)
        NSLayoutConstraint.activate([
             settingsButton.widthAnchor.constraint(equalToConstant: 40),
             settingsButton.heightAnchor.constraint(equalToConstant: 40),
             settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 95),
             settingsButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20)
        ])
    }
    
    @objc func tapSettingsButton() {
        screenManager.openSettings(parent: self)
    }
    
    func setupLocationButton() {
        let locationButton = MapButton()
        locationButton.configure(image: "location.north.fill")
        locationButton.addTarget(self, action: #selector(mapToLocation), for: .touchUpInside)
        view.addSubview(locationButton)
        NSLayoutConstraint.activate([
             locationButton.widthAnchor.constraint(equalToConstant: 40),
             locationButton.heightAnchor.constraint(equalToConstant: 40),
             locationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
             locationButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20)
        ])
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
        savedNodesButton.configure(image: "square.and.arrow.up.fill")
        savedNodesButton.addTarget(self, action: #selector(tapSavedNodesButton), for: .touchUpInside)
        view.addSubview(savedNodesButton)
        NSLayoutConstraint.activate([
             savedNodesButton.widthAnchor.constraint(equalToConstant: 40),
             savedNodesButton.heightAnchor.constraint(equalToConstant: 40),
             savedNodesButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 205),
             savedNodesButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20)
        ])
    }
    
    func updateAddNodeButton() {
        if mapView.mapZoomLevel > 16.0 {
            addNodeButton.alpha = 1
        } else {
            addNodeButton.alpha = 0.5
        }
    }
    
    @objc func tapSavedNodesButton() {
        if AppSettings.settings.savedObjects.count == 0 && AppSettings.settings.deletedObjects.count == 0 {
            Alert.showAlert("Changeset is empty")
            return
        }
        screenManager.openSavedNodesVC(parent: self)
    }
        
    func setDrawButton() {
        let drawButton = DrawButton()
        drawButton.configure(image: "paintbrush.pointed.fill")
        drawButton.addTarget(self, action: #selector(tapDrawButton), for: .touchUpInside)
        view.addSubview(drawButton)
        NSLayoutConstraint.activate([
            drawButton.widthAnchor.constraint(equalToConstant: 40),
            drawButton.heightAnchor.constraint(equalToConstant: 40),
            drawButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 260),
            drawButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20)
        ])
    }
    
    @objc func tapDrawButton(_ sender: DrawButton) {
        sender.isActive = !sender.isActive
        if sender.isActive {
            setCenterMap()
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                guard let self = self else { return }
                self.addNodeButtonTopConstraint.constant = 310
                self.view.layoutIfNeeded()
            })
        } else {
            centerIcon.removeFromSuperview()
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                guard let self = self else { return }
                self.addNodeButtonTopConstraint.constant = 260
                self.view.layoutIfNeeded()
            })
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
        addNodeButton.configure(image: "addnode")
        addNodeButton.addTarget(self, action: #selector(tapAddNodeButton), for: .touchUpInside)
        view.addSubview(addNodeButton)
        addNodeButtonTopConstraint = NSLayoutConstraint(item: addNodeButton, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 260)
        NSLayoutConstraint.activate([
             addNodeButton.widthAnchor.constraint(equalToConstant: 40),
             addNodeButton.heightAnchor.constraint(equalToConstant: 40),
             addNodeButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
             addNodeButtonTopConstraint
        ])
    }
    
    @objc func tapAddNodeButton() {
        guard mapView.mapZoomLevel > 16 else {
            Alert.showAlert("Zoom in for a more accurate location determination!")
            return
        }
        if !mapClient.checkMapcenter(center: mapView.mapGeoCenter) {
            Alert.showAlert("Load the data before adding points")
            UIView.animate(withDuration: 0.5, animations: { [weak self] in
                self?.downloadButton.backgroundColor = .red
            }, completion: { [weak self] _ in
                UIView.animate(withDuration: 0.5, delay: 2, options: [.allowUserInteraction], animations: {
                    self?.downloadButton.backgroundColor = .white
                })
            })
            return
        }
        let geoPoint = mapView.makeGeoPoint(fromDisplay: mapView.center)
        let glPoint = GLMapPoint(geoPoint: geoPoint)
        // To send the created objects to the server, you need to assign them an id < 0. To prevent duplicate IDs, the AppSettings.settings.nextId variable has been created, which reduces the id by 1 each time.
        let point = GLMapVectorPoint(glPoint) as GLMapVectorObject
        let id = AppSettings.settings.nextID
        point.setValue(String(id), forKey: "@id")
        let object = OSMAnyObject(type: .node, id: id, version: 0, changeset: 0, lat: geoPoint.lat, lon: geoPoint.lon, tag: [], nd: [], nodes: [:], members: [], vector: point)
        screenManager.editObject(parent: self, object: object)
    }
    
    //  Test button and its target for debugging convenience.
    func setTestButton() {
        let testButton = MapButton()
        testButton.configure(image: "pencil")
        testButton.addTarget(self, action: #selector(tapTestButton), for: .touchUpInside)
        view.addSubview(testButton)
        NSLayoutConstraint.activate([
             testButton.widthAnchor.constraint(equalToConstant: 40),
             testButton.heightAnchor.constraint(equalToConstant: 40),
             testButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
             testButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
        ])
    }
    
    @objc func tapTestButton() {
//        let vc = LogsViewController()
//        let navVC = SheetNavigationController(rootViewController: vc)
//        screenManager.slideViewController(parent: self, navVC: navVC)
    }
}

// MARK: MapClientProtocol

extension MapViewController: MapClientProtocol {
    func addDrawble(layer: GLMapDrawable) {
        mapView.add(layer)
    }
        
    func removeDrawble(layer: GLMapDrawable) {
        mapView.remove(layer)
    }
    
    func startDownload() {
        indicator.startAnimating()
    }
    
    func endDownload() {
        indicator.stopAnimating()
    }
}

// MARK: ShowTappedObject

extension MapViewController: UpdateSourceDataProtocol {
    //  The method updates the uploaded data. It is called from the tag editing controller and the saved objects display controller, after the changes have been successfully sent to the server.
    func updateSourceData() {
        mapClient.lastCenter = GLMapGeoPoint(lat: 0, lon: 0)
        Task {
            try await mapClient.getSourceBbox(mapCenter: mapView.mapGeoCenter)
            indicator.stopAnimating()
        }
    }
}

// MARK: UIGestureRecognizerDelegate

extension MapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool { return true }
    
    //  The method searches for vector objects under the tap. If 1 object is detected, it goes to the controller for editing its tags, if > 1, it offers to select an object from the tapped ones.
    @objc func getObjects(sender: UITapGestureRecognizer) {
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
                screenManager.editObject(parent: self, object: first)
            }
        default:
            // Moves the tapped object to the visible part of the map.
            let centerPoint = mapView.makeGeoPoint(fromDisplay: touchPoint)
            mapView.animate({ [weak self] animation in
                guard let self = self else { return }
                animation.duration = animationDuration
                animation.transition = .linear
                self.mapView.mapGeoCenter = centerPoint
            })
            screenManager.openSelectObjectVC(parent: self, objects: tapObjects)
        }
    }
}

// MARK: CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
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
}
