//
//  InfoObjectViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 05.04.2023.
//

import UIKit

//  A simple controller for displaying brief information about the object being edited.
class InfoObjectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var object: OSMAnyObject
    
    var dismissClosure: (() -> Void)?
    
    var tableView = UITableView()
    var cellId = "cell"
    var tableData: [String] = []
    
    init(object: OSMAnyObject) {
        self.object = object
        super.init(nibName: nil, bundle: nil)
        fillData()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setTitleView()
        setTableView()
    }
    
    override func viewDidDisappear(_: Bool) {
        if let clouser = dismissClosure {
            clouser()
        }
    }
    
    func setTitleView() {
        let titleView = SettingsTitleView()
        titleView.icon.image = UIImage(named: "info")
        titleView.label.text = "Info"
        titleView.addConstraints([
            titleView.heightAnchor.constraint(equalToConstant: 30),
        ])
        navigationItem.titleView = titleView
    }
    
    func setTableView() {
        tableView.rowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
    }
    
    func fillData() {
        tableData = []
        tableData.append("Type: " + object.type.rawValue)
        tableData.append("ID: \(object.id)")
        tableData.append("Changeset: \(object.changeset)")
        tableData.append("Tags:")
        var tags: [String] = []
        for (key, value) in object.oldTags {
            tags.append(key + "=" + value)
        }
        tags.sort()
        tableData += tags
        tags = []
        if NSDictionary(dictionary: object.oldTags).isEqual(to: AppSettings.settings.newProperties) {
            return
        } else {
            tableData.append("New tags:")
            for (key, value) in AppSettings.settings.newProperties {
                tags.append(key + "=" + value)
            }
            tags.sort()
            tableData += tags
        }
    }
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = tableData[indexPath.row]
        return cell
    }
}
