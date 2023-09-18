//
//  OverpasViewController.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 16.09.2023.
//

import UIKit
import SafariServices

class OverpasMainViewController: ScrollViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Overpas API"
        view.backgroundColor = .systemBackground
        
        setElements()
    }
    
    private func setElements() {
        let infoLabel = UILabel()
        infoLabel.text = "You can download data using the Overpass API."
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
        
        let cell0 = OverpasVariantView()
        cell0.configure(iconName: "square.dashed",
                        text: "Search around the center of the map. The bbox is calculated from the center of your map. To change the bbox, return to the map screen, shift the center. You can adjust the bbox size later.",
                        showSeparator: false)
        cell0.tapClosure = { [weak self] in
            let vc = OverpasBboxViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        scrollView.addSubview(cell0)
        
        let cell1 = OverpasVariantView()
        cell1.configure(iconName: "house.and.flag",
                        text: "Searching for objects in relation with the entered name. If you need a search not related to the relation, and you are proficient in Overpass API, enter the query manually.",
                        showSeparator: true)
        cell1.tapClosure = { [weak self] in
            let vc = OverpasRelationViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        scrollView.addSubview(cell1)
        
        let cell2 = OverpasVariantView()
        cell2.configure(iconName: "hand.raised",
                        text: "Fully manual query construction",
                        showSeparator: true)
        cell2.tapClosure = { [weak self] in
            let vc = OverpasManualyViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        scrollView.addSubview(cell2)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            infoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            infoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            helpLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 10),
            helpLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            helpLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            cell0.topAnchor.constraint(equalTo: helpLabel.bottomAnchor, constant: 10),
            cell0.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cell0.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            cell1.topAnchor.constraint(equalTo: cell0.bottomAnchor),
            cell1.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cell1.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            cell2.topAnchor.constraint(equalTo: cell1.bottomAnchor),
            cell2.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cell2.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            scrollView.bottomAnchor.constraint(equalTo: cell2.bottomAnchor)
        ])
    }
    
    @objc private func tapAPIHelp() {
        let link = "https://dev.overpass-api.de/overpass-doc/en/index.html"
        SFSafariViewController.present(parent: self, url: link)
    }
    
}

