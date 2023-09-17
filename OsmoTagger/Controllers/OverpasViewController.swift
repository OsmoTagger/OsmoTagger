//
//  OverpasViewController.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 16.09.2023.
//

import GLMap
import UIKit
import SafariServices

class OverpasViewController: ScrollViewController {
    
    let overpasClient = OverpasClient()
    
    var location: GLMapGeoPoint
    
    let typeDescriptionLabel = UILabel()
    let parameterLabel = UILabel()
    let parameterField = UITextView()
    let tagField = UITextField()
    let requestLabel = UILabel()
    let sendButton = UIButton()
    
    init(location: GLMapGeoPoint) {
        self.location = location
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Overpas API"
        view.backgroundColor = .systemBackground
        
        overpasClient.delegate = self
        
        setHelpButton()
        setElemets()
    }
    
    override func endEdit() {
        super.endEdit()
        var request: String
        switch AppSettings.settings.overpasRequesType {
        case .bbox:
            return
        case .cityName:
            guard let town = parameterField.text,
                  let tag = tagField.text,
                  town != "",
                  tag != "" else { return }
            request = "data=area[name=\"\(town)\"];nwr[\(tag)](area);out center;"
        case .manualy:
            return
        }
        print(requestLabel.frame)
        requestLabel.text = request
    }
    
    private func setElemets() {
        let infoLabel = UILabel()
        infoLabel.text = "You can download data using the Overpass API. This can be done by specifying the map's bbox, the city name, or by generating the query manually."
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(infoLabel)
        
        let helpLabel = UILabel()
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        let text = "Overpass API help."
        let underlinedText = NSAttributedString(string: text, attributes: underlineAttribute)
        helpLabel.attributedText = underlinedText
        helpLabel.textAlignment = .center
        helpLabel.numberOfLines = 0
        helpLabel.textColor = .systemBlue
        helpLabel.isUserInteractionEnabled = true
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        let helpTap = UITapGestureRecognizer(target: self, action: #selector(tapAPIHelp))
        helpTap.delegate = self
        helpLabel.addGestureRecognizer(helpTap)
        scrollView.addSubview(helpLabel)
        
        let typeLabel = UILabel()
        typeLabel.textAlignment = .left
        typeLabel.text = "Select the request type"
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(typeLabel)
        
        let typeButton = UIButton(configuration: .borderedTinted())
        setTypeButton(button: typeButton)
        scrollView.addSubview(typeButton)
        
        typeDescriptionLabel.numberOfLines = 0
        typeDescriptionLabel.font = .systemFont(ofSize: 14)
        setDescriptionLabelsText()
        typeDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(typeDescriptionLabel)
        
        let typeHelp = UIImageView()
        typeHelp.image = UIImage(systemName: "questionmark.circle")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        let typeHelpTap = UITapGestureRecognizer(target: self, action: #selector(tapTypeHelp))
        typeHelpTap.delegate = self
        typeHelp.isUserInteractionEnabled = true
        typeHelp.addGestureRecognizer(typeHelpTap)
        typeHelp.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(typeHelp)
        
        parameterLabel.numberOfLines = 0
        parameterLabel.font = .systemFont(ofSize: 14)
        parameterLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(parameterLabel)
        parameterField.font = .systemFont(ofSize: 16)
        parameterField.layer.cornerRadius = 6
        parameterField.layer.borderColor = UIColor.systemGray.cgColor
        parameterField.layer.borderWidth = 2
        parameterField.translatesAutoresizingMaskIntoConstraints = false
        if AppSettings.settings.overpasRequesType == .bbox {
            setBboxType()
        }
        scrollView.addSubview(parameterField)
        
        let tagDescriptionLabel = UILabel()
        tagDescriptionLabel.numberOfLines = 0
        tagDescriptionLabel.font = .systemFont(ofSize: 14)
        tagDescriptionLabel.text = "Enter a tag=value pair. For example, amenity=cafe."
        tagDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(tagDescriptionLabel)
        
        tagField.layer.cornerRadius = 4
        tagField.layer.borderColor = UIColor.systemGray.cgColor
        tagField.layer.borderWidth = 2
        tagField.autocapitalizationType = .none
        tagField.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(tagField)
        
        let requestDescription = UILabel()
        requestDescription.numberOfLines = 0
        requestDescription.font = .systemFont(ofSize: 14)
        requestDescription.text = "Request:\nhttps://overpass-api.de/api/interpreter?"
        requestDescription.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(requestDescription)
        
        requestLabel.layer.cornerRadius = 4
        requestLabel.layer.borderColor = UIColor.systemGray.cgColor
        requestLabel.layer.borderWidth = 2
        requestLabel.numberOfLines = 0
        requestLabel.font = .systemFont(ofSize: 16)
        requestLabel.text = " "
        requestLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(requestLabel)
        
        
        
        sendButton.backgroundColor = .systemBlue
        sendButton.setTitle("Send", for: .normal)
        sendButton.layer.cornerRadius = 16
        sendButton.addTarget(self, action: #selector(tapSend), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            infoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            infoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            helpLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 10),
            helpLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            helpLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            typeLabel.topAnchor.constraint(equalTo: helpLabel.bottomAnchor, constant: 20),
            typeLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            
            typeHelp.leadingAnchor.constraint(equalTo: typeLabel.trailingAnchor, constant: 5),
            typeHelp.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor),
            typeHelp.widthAnchor.constraint(equalToConstant: 24),
            typeHelp.heightAnchor.constraint(equalToConstant: 24),
            
            typeButton.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 10),
            typeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            typeButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            
            typeDescriptionLabel.topAnchor.constraint(greaterThanOrEqualTo: typeHelp.bottomAnchor),
            typeDescriptionLabel.centerYAnchor.constraint(equalTo: typeButton.centerYAnchor),
            typeDescriptionLabel.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            typeDescriptionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            parameterLabel.topAnchor.constraint(equalTo: typeButton.bottomAnchor, constant: 20),
            parameterLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            parameterLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            parameterField.topAnchor.constraint(equalTo: parameterLabel.bottomAnchor, constant: 5),
            parameterField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            parameterField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            parameterField.heightAnchor.constraint(equalToConstant: 80),
            
            tagDescriptionLabel.topAnchor.constraint(equalTo: parameterField.bottomAnchor, constant: 20),
            tagDescriptionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            tagDescriptionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            tagField.topAnchor.constraint(equalTo: tagDescriptionLabel.bottomAnchor, constant: 5),
            tagField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            tagField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            tagField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            requestDescription.topAnchor.constraint(equalTo: tagField.bottomAnchor, constant: 20),
            requestDescription.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            requestDescription.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            requestLabel.topAnchor.constraint(equalTo: requestDescription.bottomAnchor, constant: 5),
            requestLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            requestLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            requestLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            sendButton.topAnchor.constraint(equalTo: requestLabel.bottomAnchor, constant: 20),
            sendButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            scrollView.bottomAnchor.constraint(equalTo: sendButton.bottomAnchor)
        ])
    }
    
    private func setDescriptionLabelsText() {
        let descText: String
        let parametrDescText: String
        switch AppSettings.settings.overpasRequesType {
        case .bbox:
            descText = "Search around the center of the map + 0.05°"
            parametrDescText = "To change the bbox, go back to the map screen, shift the center, and return to the current screen."
        case .cityName:
            descText = "Searching for objects in a relation with the entered name."
            parametrDescText = "Enter the name of the locality. For example, Köln, London, Москва."
        case .manualy:
            descText = "Fully manual query construction"
            parametrDescText = "Enter the query text completely in manual mode into this field."
        }
        typeDescriptionLabel.text = descText
        parameterLabel.text = parametrDescText
    }
    
    private func setTypeButton(button: UIButton) {
        let optionClosure: UIActionHandler = { [weak self, weak button] (action: UIAction) in
            switch action.title {
            case "Bbox":
                self?.setBboxType()
            case "In the city":
                self?.setCityNameType()
            case "Manually":
                self?.setManualyType()
            default:
                return
            }
            button?.setTitle(action.title, for: .normal)
        }
        var optionsArray = [UIAction]()
        let action0 = UIAction(title: "Bbox", image: UIImage(systemName: "square.dashed"), handler: optionClosure)
        if AppSettings.settings.overpasRequesType == .bbox {
            action0.state = .on
            button.setTitle(action0.title, for: .normal)
        }
        optionsArray.append(action0)
        let action1 = UIAction(title: "In the city", image: UIImage(systemName: "house.and.flag"), handler: optionClosure)
        if AppSettings.settings.overpasRequesType == .cityName {
            action1.state = .on
            button.setTitle(action1.title, for: .normal)
        }
        optionsArray.append(action1)
        let action2 = UIAction(title: "Manually", image: UIImage(systemName: "hand.raised"), handler: optionClosure)
        if AppSettings.settings.overpasRequesType == .manualy {
            action2.state = .on
            button.setTitle(action2.title, for: .normal)
        }
        optionsArray.append(action2)
        let optionsMenu = UIMenu(title: "", image: nil, identifier: nil, options: .singleSelection, children: optionsArray)
        button.menu = optionsMenu
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = false
        let image = UIImage(systemName: "chevron.down")?.withTintColor(.buttonColor, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        button.setTitleColor(.buttonColor, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
    }
    
    @objc private func tapSend(_ sender: UIButton) {
        print("taptap")
        let server = "https://overpass-api.de/api/interpreter?"
        guard let query = requestLabel.text else {
            showAction(message: "Check parameters!", addAlerts: [])
            return
        }
        let url = server + query
        print(url)
        Task {
            do {
                try await overpasClient.getData(urlStr: url)
            } catch {
                print(error)
            }
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
    
    // MARK: User actions
    
    private func setBboxType() {
        AppSettings.settings.overpasRequesType = .bbox
        setDescriptionLabelsText()
        parameterField.backgroundColor = .systemGray6
        parameterField.isUserInteractionEnabled = false
        let diff = 0.05
        let latMin = location.lat - diff
        let latMax = location.lat + diff
        let lonMin = location.lon - diff
        let lonMax = location.lon + diff
        let text = "nwr(\(latMin),\(lonMin),\(latMax),\(lonMax);out;"
        parameterField.text = text
    }
    
    private func setCityNameType() {
        AppSettings.settings.overpasRequesType = .cityName
        setDescriptionLabelsText()
        parameterField.backgroundColor = .clear
        parameterField.isUserInteractionEnabled = true
        parameterField.text = nil
    }
    
    private func setManualyType() {
        AppSettings.settings.overpasRequesType = .manualy
        setDescriptionLabelsText()
        parameterField.backgroundColor = .clear
        parameterField.isUserInteractionEnabled = true
    }
    
    @objc private func tapHelp(_ sender: UIBarItem) {
        print("tap")
    }
    
    @objc private func tapAPIHelp() {
        let link = "https://dev.overpass-api.de/overpass-doc/en/index.html"
        guard let url = URL(string: link) else {return}
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }
    
    @objc private func tapTypeHelp(_ sender: UIGestureRecognizer) {
        print("tapTypeHelp")
    }
    
}

// MARK: OverpasProtocol
extension OverpasViewController: OverpasProtocol {
    func downloadProgress(_ loaded: Int64) {
        let loadedMb = Double(loaded) / 1_048_576.0
        print(String(format: "%.3f", loadedMb))
    }
    
    func downloadCompleted(with result: URL) {
        print(result.absoluteString)
    }
}

