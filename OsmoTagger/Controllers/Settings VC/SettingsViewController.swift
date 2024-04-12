//
//  SettingsViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 12.04.2023.
//

import UIKit

//  The main settings controller.
class SettingsViewController: SheetViewController, UITableViewDelegate, UITableViewDataSource {
    var tableView = UITableView()
    var cellId = "cell"
    var tableData: [SettingsTableData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        fillData()
        setTitleView()
        setTableView()
    }
    
    override func viewWillAppear(_: Bool) {
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewDidDisappear(_: Bool) {}
    
    func fillData() {
        let general = SettingsTableData(name: nil, items: [
            SettingsCellData(icon: "person.crop.circle", text: "Authorization", link: ""),
            SettingsCellData(icon: "smartphone.png", text: "Main screen", link: ""),
            SettingsCellData(icon: "questionmark.circle", text: "Quick guide", link: ""),
            SettingsCellData(icon: "logsIcon", text: "App logs", link: ""),
        ])
        tableData.append(general)
        
        let gitText = "Join us at GitHub"
        let support = SettingsTableData(name: "Support and development", items: [
            SettingsCellData(icon: "gitIcon.png", text: gitText, link: "https://github.com/OsmoTagger/OsmoTagger"),
        ])
        tableData.append(support)
        let osmText = "Map data (c) Openstreetmap contributors"
        let glText = "Map rendering by GLMap"
        let osmiumText = "Data conversion by Osmium"
        let josmText = "Presets and images from JOSM"
        let second = SettingsTableData(name: "Thanks", items: [
            SettingsCellData(icon: "osmIcon.jpg", text: osmText, link: "https://www.openstreetmap.org/"),
            SettingsCellData(icon: "globusIcon.png", text: glText, link: "https://globus.software/"),
            SettingsCellData(icon: "osmiumIcon.png", text: osmiumText, link: "https://osmcode.org/"),
            SettingsCellData(icon: "josmIcon.png", text: josmText, link: "https://josm.openstreetmap.de/"),
        ])
        tableData.append(second)
        let licenseText = "GPLv3"
        let third = SettingsTableData(name: "License", items: [
            SettingsCellData(icon: "gnuIcon.png", text: licenseText, link: "https://www.gnu.org/licenses/gpl-3.0.html"),
        ])
        tableData.append(third)
    }
    
    func setTitleView() {
        let titleView = SettingsTitleView()
        titleView.icon.image = UIImage(systemName: "gearshape")
        titleView.label.text = "Settings"
        titleView.addConstraints([
            titleView.heightAnchor.constraint(equalToConstant: 30),
        ])
        navigationItem.titleView = titleView
    }
    
    func setTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SimpleCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    func numberOfSections(in _: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableData[section].name
    }
    
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].items.count
    }
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        var vc: UIViewController
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                vc = AuthViewController()
            case 1:
                vc = ScreenSettingsViewController()
            case 2:
                vc = QuickGuideViewController()
            case 3:
                vc = LogsViewController()
            default:
                return
            }
            navigationController?.pushViewController(vc, animated: true)
        default:
            let link = tableData[indexPath.section].items[indexPath.row].link
            guard let url = URL(string: link) else {
                showAction(message: "Error create url: \(link)", addAlerts: [])
                return
            }
            UIApplication.shared.open(url)
        }
    }
        
    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SimpleCell else {
            let cellFail = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
            cellFail.textLabel?.text = "Point data loading error"
            return cellFail
        }
        let data = tableData[indexPath.section].items[indexPath.row]
        cell.icon.icon.image = UIImage(named: data.icon)
        cell.label.text = data.text
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}
