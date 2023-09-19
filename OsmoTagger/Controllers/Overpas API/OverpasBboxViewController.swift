//
//  OverpasBboxViewController.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 18.09.2023.
//

import UIKit
import GLMap

class OverpasBboxViewController: ScrollViewController {
    
    var mapCenter: GLMapGeoPoint?
    
    let overpasClient = OverpasClient()
    var dataUrl: URL?
    
    let tagField = UITextField()
    let bboxField = UITextField()
    let downloadView = OverpasDownloadView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overpasClient.delegate = self
        
        title = "Find in bbox"
        view.backgroundColor = .systemBackground
        if let navVC = navigationController as? OverpasNavigationController {
            self.mapCenter = navVC.mapCenter
        }
        
        setElements()
    }
    
    
    private func setElements() {
        let locationLabel = UILabel()
        locationLabel.numberOfLines = 0
        locationLabel.textAlignment = .center
        if let center = mapCenter {
            locationLabel.text = "Map center:" + "\n" + "lat: \(center.lat)\nlon: \(center.lon)"
        }
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(locationLabel)
        
        let bboxSizeDescLabel = UILabel()
        bboxSizeDescLabel.numberOfLines = 0
        bboxSizeDescLabel.textAlignment = .center
        bboxSizeDescLabel.font = .systemFont(ofSize: 14)
        bboxSizeDescLabel.text = "Set bbox size"
        bboxSizeDescLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(bboxSizeDescLabel)
        
        bboxField.textAlignment = .center
        bboxField.text = "0.05"
        bboxField.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(bboxField)
        
        let tagDescription = UILabel()
        tagDescription.font = .systemFont(ofSize: 14)
        tagDescription.text = "Enter a tag=value pair. For example, amenity=cafe."
        tagDescription.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(tagDescription)
        
        tagField.layer.cornerRadius = 4
        tagField.layer.borderColor = UIColor.systemGray.cgColor
        tagField.layer.borderWidth = 2
        tagField.autocapitalizationType = .none
        tagField.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(tagField)
        
        
        var config = UIButton.Configuration.borderedProminent()
        config.image = UIImage(systemName: "square.and.arrow.up")
        config.titlePadding = 4
        let sendButton = UIButton(configuration: config)
        sendButton.addTarget(self, action: #selector(tapSend), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(sendButton)
        
        downloadView.showClosure = { [weak self] in
            guard let self = self,
                  let dataUrl = dataUrl,
                  let navVC = navigationController as? OverpasNavigationController else {return}
            print("+++++++")
            print(dataUrl)
            let data = try? Data(contentsOf: dataUrl)
            print(data?.count)
            navVC.callbackClosure?(dataUrl)
            navVC.dismiss(animated: true)
        }
        downloadView.isHidden = true
        scrollView.addSubview(downloadView)
        
        let but = UIButton()
        but.backgroundColor = .systemBlue
        but.setTitle("AAAAAA", for: .normal)
        but.addTarget(self, action: #selector(tap), for: .touchUpInside)
        but.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(but)
        
        let spacing: CGFloat = 10
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: spacing),
            locationLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            locationLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            
            bboxSizeDescLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: spacing * 2),
            bboxSizeDescLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            bboxSizeDescLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            
            bboxField.topAnchor.constraint(equalTo: bboxSizeDescLabel.bottomAnchor, constant: 3),
            bboxField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            bboxField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            
            tagDescription.topAnchor.constraint(equalTo: bboxField.bottomAnchor, constant: 2 * spacing),
            tagDescription.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            tagDescription.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            
            tagField.topAnchor.constraint(equalTo: tagDescription.bottomAnchor, constant: spacing / 2),
            tagField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            tagField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -spacing),
            tagField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            sendButton.centerYAnchor.constraint(equalTo: tagField.centerYAnchor),
            sendButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40),
            
            downloadView.topAnchor.constraint(equalTo: tagField.bottomAnchor, constant: 2 * spacing),
            downloadView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            downloadView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            
            but.topAnchor.constraint(equalTo: downloadView.bottomAnchor, constant: 2 * spacing),
            but.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            
            scrollView.bottomAnchor.constraint(equalTo: but.bottomAnchor)
        ])
    }
    
    @objc private func tap() {
        if let url = dataUrl {
            print(url)
            let data = try? Data(contentsOf: url)
            print(data?.count)
        }
    }
// https://overpass-api.de/api/interpreter?data=nwr[amenity=cafe](56.10509142344276,40.35436862036586,56.20509142344275,40.454368620365855);out%20center;
    
// https://overpass-api.de/api/interpreter?data=nwr[amenity=cafe](56.10506546783101,40.35432201698423,56.205065467831005,40.45432201698422);out center;
    @objc private func tapSend() {
        downloadView.isHidden = false
        let serverStr = "https://overpass-api.de/api/interpreter?data=nwr"
        guard let bboxStr = bboxField.text,
              let bbox = Double(bboxStr),
              let tag = tagField.text,
              tag != "",
              let mapCenter = mapCenter else {return}
        let latMin = mapCenter.lat - bbox
        let latMax = mapCenter.lat + bbox
        let lonMin = mapCenter.lon - bbox
        let lonMax = mapCenter.lon + bbox
        let bboxUrl = "(\(latMin),\(lonMin),\(latMax),\(lonMax))"
        let tagUrl = "[\(tag)]"
        let url = serverStr + tagUrl + bboxUrl + ";out geom;[out:json]"
        print(url)
        Task {
            do {
                try await overpasClient.getData(urlStr: url)
            } catch {
                let message = error as? String ?? "Error"
                downloadView.setResult(success: false, text: message)
            }
        }
    }
    
}

extension OverpasBboxViewController: OverpasProtocol {
    func downloadProgress(_ loaded: Int64) {
        downloadView.setDownloadSize(size: loaded)
    }
    
    func downloadCompleted(with result: URL) {
        dataUrl = result
        DispatchQueue.main.async {
            if let navVC = self.navigationController as? OverpasNavigationController { 
                navVC.callbackClosure?(result)
            }
        }
        
    }
    
    
}
