//
//  QuickGuideViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 17.04.2023.
//

import UIKit

//  The controller of a brief manual for use.
class QuickGuideViewController: ScrollViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitleView()
        view.backgroundColor = .systemBackground
        
        setupContentView()
    }
    
    override func viewWillAppear(_: Bool) {
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    func setupContentView() {
        let image0 = UIImageView(image: UIImage(named: "guide_download"))
        image0.layer.borderColor = UIColor.systemGray.cgColor
        image0.layer.borderWidth = 3
        image0.layer.cornerRadius = 4
        image0.contentMode = .scaleAspectFit
        image0.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(image0)
        let label0 = UILabel()
        label0.numberOfLines = 0
        label0.text = "To download data from the server, click the 'Download' button. Zoom in until the indicator turns green, and wait for the data to finish loading and indexing."
        label0.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(label0)
        
        let image1 = UIImageView(image: UIImage(named: "guide_edit"))
        image1.layer.borderColor = UIColor.systemGray.cgColor
        image1.layer.borderWidth = 3
        image1.layer.cornerRadius = 4
        image1.contentMode = .scaleAspectFit
        image1.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(image1)
        let label1 = UILabel()
        label1.numberOfLines = 0
        label1.text = "After tapping on an object, you can delete tags, add new ones from ready-made presets or manually."
        label1.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(label1)
        
        let image3 = UIImageView(image: UIImage(named: "guide_send"))
        image3.layer.borderColor = UIColor.systemGray.cgColor
        image3.layer.borderWidth = 3
        image3.layer.cornerRadius = 4
        image3.contentMode = .scaleAspectFit
        image3.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(image3)
        let label3 = UILabel()
        label3.numberOfLines = 0
        label3.text = "All changes made are automatically stored in memory. To view the changes, click the 'changeset' button with an indicator of the number of changed objects."
        label3.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(label3)
        
        let image4 = UIImageView(image: UIImage(named: "guide_add"))
        image4.layer.borderColor = UIColor.gray.cgColor
        image4.layer.borderWidth = 3
        image4.layer.cornerRadius = 4
        image4.contentMode = .scaleAspectFit
        image4.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(image4)
        let label4 = UILabel()
        label4.numberOfLines = 0
        label4.text = "To create a new point, press the 'Draw' button, wait for the data to load, set the exact positioning of the point, and then click the 'Add' button.\nIn the current version, it is possible to add and delete only individual points that are not referenced by lines."
        label4.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(label4)
        
        NSLayoutConstraint.activate([
            image0.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            image0.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 25),
            image0.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -25),
            image0.widthAnchor.constraint(equalTo: image0.heightAnchor, multiplier: 1),
            label0.topAnchor.constraint(equalTo: image0.bottomAnchor, constant: 5),
            label0.leftAnchor.constraint(equalTo: image0.leftAnchor),
            label0.rightAnchor.constraint(equalTo: image0.rightAnchor),
            
            image1.topAnchor.constraint(equalTo: label0.bottomAnchor, constant: 20),
            image1.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 25),
            image1.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -25),
            image1.widthAnchor.constraint(equalTo: image1.heightAnchor, multiplier: 1),
            label1.topAnchor.constraint(equalTo: image1.bottomAnchor, constant: 5),
            label1.leftAnchor.constraint(equalTo: image1.leftAnchor),
            label1.rightAnchor.constraint(equalTo: image1.rightAnchor),
            
            image3.topAnchor.constraint(equalTo: label1.bottomAnchor, constant: 20),
            image3.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 25),
            image3.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -25),
            image3.widthAnchor.constraint(equalTo: image3.heightAnchor, multiplier: 1),
            label3.topAnchor.constraint(equalTo: image3.bottomAnchor, constant: 5),
            label3.leftAnchor.constraint(equalTo: image3.leftAnchor),
            label3.rightAnchor.constraint(equalTo: image3.rightAnchor),
            
            image4.topAnchor.constraint(equalTo: label3.bottomAnchor, constant: 20),
            image4.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 25),
            image4.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -25),
            image4.widthAnchor.constraint(equalTo: image4.heightAnchor, multiplier: 1),
            label4.topAnchor.constraint(equalTo: image4.bottomAnchor, constant: 5),
            label4.leftAnchor.constraint(equalTo: image4.leftAnchor),
            label4.rightAnchor.constraint(equalTo: image4.rightAnchor),
            
            scrollView.bottomAnchor.constraint(equalTo: label4.bottomAnchor, constant: 20)
        ])
    }
    
    func setTitleView() {
        let titleView = SettingsTitleView()
        titleView.icon.image = UIImage(systemName: "questionmark.circle")
        titleView.label.text = "Quick guide"
        titleView.addConstraints([
            titleView.heightAnchor.constraint(equalToConstant: 30),
        ])
        navigationItem.titleView = titleView
    }
}
