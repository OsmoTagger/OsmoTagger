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
    //  map and location service
    var mapView: GLMapView!
    private let locationManager = CLLocationManager()
    
    //  The variable in which the reference to the open UINavigationController is stored. When initializing any controller, there is a check for nil, for example, in the goToSAvedNodesVC() method.
    var navController: SheetNavigationController?
    
    // plus zoom, minus zoom, map angle
    let mapButtons = MapButtonsView()
    
    //  Buttons
    let downloadButton = UIButton()
    let indicator = DownloadIndicatorView()
    let centerIcon = UIImageView()
    let addNodeButton = UIButton()
    var addNodeButtonTopConstraint = NSLayoutConstraint()
    
    //  Displays the object that was tapped and whose properties are currently being edited (yellow).
    var editDrawble = GLMapVectorLayer(drawOrder: 4)
    
    let animationDuration = 0.3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Creating and adding MapView
        setMapView()
        
        mapClient.delegate = self
        
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
        // setTestButton()
        
        // Zoom in and zoom out buttons, map rotation button
        setMapButtons()
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
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leftAnchor.constraint(equalTo: view.leftAnchor),
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
            mapButtons.angleButton.image.transform = CGAffineTransform(rotationAngle: -radian)
            
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
    func setMapButtons() {
        mapButtons.plusButton.addTarget(self, action: #selector(tapPlusButton), for: .touchUpInside)
        mapButtons.minusButton.addTarget(self, action: #selector(tapMinusButton), for: .touchUpInside)
        let angleTap = UITapGestureRecognizer()
        angleTap.delegate = self
        angleTap.addTarget(self, action: #selector(tapAngleButton))
        mapButtons.angleButton.addGestureRecognizer(angleTap)
        view.addSubview(mapButtons)
        NSLayoutConstraint.activate([
            mapButtons.heightAnchor.constraint(equalToConstant: 150),
            mapButtons.widthAnchor.constraint(equalToConstant: 40),
            mapButtons.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            mapButtons.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 300),
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
    
    //  The indicator that appears in place of the data download button.
    func setLoadIndicator() {
        indicator.isUserInteractionEnabled = false
        indicator.stopAnimating()
        view.addSubview(indicator)
        
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.widthAnchor.constraint(equalToConstant: 20),
            indicator.heightAnchor.constraint(equalToConstant: 20),
            indicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            indicator.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20),
        ])
    }
    
    func setDownloadButton() {
        downloadButton.layer.cornerRadius = 5
        downloadButton.backgroundColor = .white
        downloadButton.setImage(UIImage(systemName: "square.and.arrow.down.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        downloadButton.addTarget(self, action: #selector(tapDownloadButton), for: .touchUpInside)
        view.addSubview(downloadButton)
        
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([downloadButton.widthAnchor.constraint(equalToConstant: 40),
                                     downloadButton.heightAnchor.constraint(equalToConstant: 40),
                                     downloadButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
                                     downloadButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10)])
    }
    
    
    @objc func tapDownloadButton() {
        downLoadData()
    }
    
    private func downLoadData() {
        Task {
            do {
                try await mapClient.getSourceBbox(mapCenter: mapView.mapGeoCenter)
            } catch {
                let message = error as? String ?? "Error load data"
                showAction(message: message, addAlerts: [])
            }
        }
    }
    
    func setupSettingsButton() {
        let settingsButton = UIButton()
        settingsButton.layer.cornerRadius = 5
        settingsButton.backgroundColor = .white
        settingsButton.setImage(UIImage(systemName: "gearshape")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        settingsButton.addTarget(self, action: #selector(tapSettingsButton), for: .touchUpInside)
        view.addSubview(settingsButton)
        
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([settingsButton.widthAnchor.constraint(equalToConstant: 40),
                                     settingsButton.heightAnchor.constraint(equalToConstant: 40),
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
        navController = SheetNavigationController(rootViewController: vc)
        guard let sheetVC = navController?.sheetPresentationController else {return}
        // open the settings in full-screen mode
        sheetVC.detents = [.large()]
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
        NSLayoutConstraint.activate([locationButton.widthAnchor.constraint(equalToConstant: 40),
                                     locationButton.heightAnchor.constraint(equalToConstant: 40),
                                     locationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
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
        NSLayoutConstraint.activate([savedNodesButton.widthAnchor.constraint(equalToConstant: 40),
                                     savedNodesButton.heightAnchor.constraint(equalToConstant: 40),
                                     savedNodesButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 205),
                                     savedNodesButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10)])
    }
    
    func updateAddNodeButton() {
        if mapView.mapZoomLevel > 16.0 {
            addNodeButton.alpha = 1
        } else {
            addNodeButton.alpha = 0.5
        }
    }
    
    @objc func tapSavedNodesButton() {
        if let viewControllers = navController?.viewControllers {
            // navController != nil
            if viewControllers[0] is SavedNodesViewController {
                if viewControllers.count == 1 {
                    return
                } else {
                    navController?.setViewControllers([viewControllers[0]], animated: true)
                }
            } else {
                // dismiss and open new navController
                navController?.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else { return }
                    self.goToSAvedNodesVC()
                })
            }
        } else {
            // navController = nil, open new navigation controller
            goToSAvedNodesVC()
        }
    }
    
    func goToSAvedNodesVC() {
        runOpenAnimation()
        let savedNodesVC = SavedNodesViewController()
        savedNodesVC.delegate = self
        navController = SheetNavigationController(rootViewController: savedNodesVC)
        navController?.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.navController = nil
            self.runCloseAnimation()
        }
        if navController != nil {
            present(navController!, animated: true, completion: nil)
        }
    }
    
    func setDrawButton() {
        let drawButton = DrawButton()
        drawButton.layer.cornerRadius = 5
        drawButton.backgroundColor = .white
        drawButton.setImage(UIImage(systemName: "paintbrush.pointed.fill"), for: .normal)
        drawButton.tintColor = .black
        drawButton.addTarget(self, action: #selector(tapDrawButton), for: .touchUpInside)
        drawButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(drawButton)
        NSLayoutConstraint.activate([
            drawButton.widthAnchor.constraint(equalToConstant: 40),
            drawButton.heightAnchor.constraint(equalToConstant: 40),
            drawButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 260),
            drawButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10),
        ])
    }
    
    @objc func tapDrawButton(_ sender: DrawButton) {
        sender.isActive = !sender.isActive
        if sender.isActive {
            setCenterMap()
            downLoadData()
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
        addNodeButton.layer.cornerRadius = 5
        addNodeButton.backgroundColor = .white
        addNodeButton.setImage(UIImage(named: "addnode"), for: .normal)
        addNodeButton.addTarget(self, action: #selector(tapAddNodeButton), for: .touchUpInside)
        view.addSubview(addNodeButton)
        addNodeButton.translatesAutoresizingMaskIntoConstraints = false
        addNodeButtonTopConstraint = NSLayoutConstraint(item: addNodeButton, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 260)
        NSLayoutConstraint.activate([addNodeButton.widthAnchor.constraint(equalToConstant: 40),
                                     addNodeButton.heightAnchor.constraint(equalToConstant: 40),
                                     addNodeButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10),
                                     addNodeButtonTopConstraint])
    }
    
    @objc func tapAddNodeButton() {
        guard mapView.mapZoomLevel > 16 else {
            showAction(message: "Zoom in for a more accurate location determination!", addAlerts: [])
            return
        }
        let geoPoint = mapView.makeGeoPoint(fromDisplay: mapView.center)
        let glPoint = GLMapPoint(geoPoint: geoPoint)
        // To send the created objects to the server, you need to assign them an id < 0. To prevent duplicate IDs, the AppSettings.settings.nextId variable has been created, which reduces the id by 1 each time.
        let point = GLMapVectorPoint(glPoint) as GLMapVectorObject
        let id = AppSettings.settings.nextID
        point.setValue(String(id), forKey: "@id")
        let object = OSMAnyObject(type: .node, id: id, version: 0, changeset: 0, lat: geoPoint.lat, lon: geoPoint.lon, tag: [], nd: [], nodes: [:], members: [], vector: point)
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
        NSLayoutConstraint.activate([testButton.widthAnchor.constraint(equalToConstant: 40),
                                     testButton.heightAnchor.constraint(equalToConstant: 40),
                                     testButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10),
                                     testButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)])
    }
    
    @objc func tapTestButton() {}
    
//    MARK: Open objects and screens

    func openObjects(objects: [OSMAnyObject]) {
        if let viewControllers = navController?.viewControllers {
            // navController != nil
            if let selectVC = viewControllers[0] as? SelectObjectViewController {
                selectVC.objects = objects
                selectVC.fillData()
                if viewControllers.count == 1 {
                    selectVC.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                } else {
                    navController?.setViewControllers([viewControllers[0]], animated: true, completion: {
                        selectVC.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                    })
                }
            } else {
                navController?.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else { return }
                    self.goToSelectVC(objects: objects)
                })
            }
        } else {
            // navController = nil, open new
            goToSelectVC(objects: objects)
        }
    }
    
    func goToSelectVC(objects: [OSMAnyObject]) {
        runOpenAnimation()
        let selectVC = SelectObjectViewController(objects: objects)
        selectVC.delegate = self
        navController = SheetNavigationController(rootViewController: selectVC)
        navController?.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.mapView.remove(self.mapClient.tappedDrawble)
            self.navController = nil
            self.runCloseAnimation()
        }
        if navController != nil {
            present(navController!, animated: true, completion: nil)
        }
    }
    
    func checkObjectInSelectVC(id: Int, objects: [OSMAnyObject]) -> Bool {
        for object in objects {
            if object.id == id {
                return true
            }
        }
        return false
    }
    
    func editVCUpdateObject(viewControllers: [UIViewController], newObject: OSMAnyObject) {
        for controller in viewControllers {
            if let infoVC = controller as? InfoObjectViewController {
                infoVC.object = newObject
                infoVC.fillData()
                infoVC.tableView.reloadData()
            }
        }
        for controller in viewControllers {
            if let editVC = controller as? EditObjectViewController {
                editVC.updateViewController(newObject: newObject)
                return
            }
        }
    }
    
    func openObject(object: OSMAnyObject) {
        if let viewControllers = navController?.viewControllers {
            // navController != nil
            if let selectVC = viewControllers[0] as? SelectObjectViewController {
                // selectVC -------------------------------
                if checkObjectInSelectVC(id: object.id, objects: selectVC.objects) {
                    if viewControllers.count > 1 {
                        editVCUpdateObject(viewControllers: viewControllers, newObject: object)
                    } else {
                        let editVC = EditObjectViewController(object: object)
                        navController?.pushViewController(editVC, animated: true)
                    }
                } else {
                    navController?.dismiss(animated: true, completion: { [weak self] in
                        guard let self = self else { return }
                        self.goToPropertiesVC(object: object)
                    })
                }
                // selectVC -------------------------------
            } else if viewControllers[0] is SavedNodesViewController {
                //  savedVC -------------------------------
                var savedObjects: [OSMAnyObject] = []
                for (_, object) in AppSettings.settings.savedObjects {
                    savedObjects.append(object)
                }
                for (_, object) in AppSettings.settings.deletedObjects {
                    savedObjects.append(object)
                }
                if checkObjectInSelectVC(id: object.id, objects: savedObjects) {
                    if viewControllers.count > 1 {
                        editVCUpdateObject(viewControllers: viewControllers, newObject: object)
                    } else {
                        let editVC = EditObjectViewController(object: object)
                        navController?.pushViewController(editVC, animated: true)
                    }
                } else {
                    navController?.dismiss(animated: true, completion: { [weak self] in
                        guard let self = self else { return }
                        self.goToPropertiesVC(object: object)
                    })
                }
                // savedVC -------------------------------
            } else if viewControllers[0] is EditObjectViewController {
                editVCUpdateObject(viewControllers: viewControllers, newObject: object)
            } else {
                navController?.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else { return }
                    self.goToPropertiesVC(object: object)
                })
            }
        } else {
            // navController = nil, open new
            goToPropertiesVC(object: object)
        }
    }
    
    //  The method opens the tag editing controller.
    //  The user can tap on the object on the visible part of the map at the moment when the editing controller is already open. Then the editable object on the controller changes to a new one.
    func goToPropertiesVC(object: OSMAnyObject) {
        runOpenAnimation()
        let editVC = EditObjectViewController(object: object)
        navController = SheetNavigationController(rootViewController: editVC)
        // When the user closes the tag editing controller, the backlight of the tapped object is removed.
        navController?.dismissClosure = { [weak self] in
            guard let self = self else { return }
            self.navController = nil
            self.runCloseAnimation()
        }
        if navController != nil {
            present(navController!, animated: true, completion: nil)
        }
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
                openObject(object: first)
            }
        default:
            // Moves the tapped object to the visible part of the map.
            let centerPoint = mapView.makeGeoPoint(fromDisplay: touchPoint)
            mapView.animate({ animation in
                animation.duration = animationDuration
                animation.transition = .linear
                mapView.mapGeoCenter = centerPoint
            }, withCompletion: { [weak self] _ in
                guard let self = self else { return }
                AppSettings.settings.lastBbox = self.mapView.bbox
            })
            openObjects(objects: tapObjects)
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
