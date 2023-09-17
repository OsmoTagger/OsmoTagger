//
//  OverpasViewController.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 16.09.2023.
//

import GLMap
import UIKit

class OverpasViewController: ScrollViewController {
    
    var location: GLMapGeoPoint?
    
    let locationField = UITextField()
    let tagField = UITextField()
    let sendButton = UIButton()
    
    init(location: GLMapGeoPoint?) {
        self.location = location
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setHelpButton()
        setElemets()
    }
    
    private func setElemets() {
        locationField.borderStyle = .roundedRect
        if let location {
            locationField.text = "lat: \(location.lat), lon: \(location.lon)"
        }
        locationField.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(locationField)
        
        tagField.borderStyle = .roundedRect
        tagField.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(tagField)
        
        sendButton.backgroundColor = .systemBlue
        sendButton.setTitle("Send", for: .normal)
        sendButton.configuration?.cornerStyle = .capsule
        sendButton.addTarget(self, action: #selector(tapSend), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            locationField.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            locationField.widthAnchor.constraint(equalToConstant: 150),
            locationField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            tagField.topAnchor.constraint(equalTo: locationField.bottomAnchor, constant: 50),
            tagField.widthAnchor.constraint(equalToConstant: 150),
            tagField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            sendButton.topAnchor.constraint(equalTo: tagField.bottomAnchor, constant: 50),
            sendButton.widthAnchor.constraint(equalToConstant: 150),
            sendButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            scrollView.bottomAnchor.constraint(equalTo: sendButton.bottomAnchor)
        ])
    }
    
    @objc private func tapSend() {
        print("taptap")
        // curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'data=area[name="Köln"];nwr[amenity=cafe](area);out center;' https://overpass-api.de/api/interpreter

        let urlStr = "https://overpass-api.de/api/interpreter?data=area[name=\"Радужный\"];nwr[amenity=cafe](area);out center;"
        Task {
            try? await OverpasClient().getData(urlStr: urlStr)
        }
        
    }
    
    private func setHelpButton() {
        let image = UIImage(systemName: "questionmark.circle")?.withTintColor(.buttonColor, renderingMode: .alwaysOriginal)
        let button = UIImageView(image: image)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHelp))
        button.addGestureRecognizer(tap)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        let barButton = UIBarButtonItem(customView: button)
        rightButtons.append(barButton)
    }
    
    @objc func tapHelp(_ sender: UIBarItem) {
        print("tap")
    }
    
}
