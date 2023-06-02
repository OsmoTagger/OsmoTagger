//
//  MainViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 12.04.2023.
//

import SafariServices
import UIKit

//  The main settings controller.
class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
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
            SettingsCellData(icon: "questionmark.circle", text: "Quick guide", link: ""),
        ])
        tableData.append(general)
        
        let telegramText = "Support and development chat"
        let channelText = "Telegram channel"
        let gitText = "Source code."
        let support = SettingsTableData(name: "Support and development", items: [
            SettingsCellData(icon: "chatIcon", text: telegramText, link: "https://t.me/OpenStreetEditor_chat"),
            SettingsCellData(icon: "channelIcon", text: channelText, link: "https://t.me/OpenStreetEditor"),
            SettingsCellData(icon: "gitIcon", text: gitText, link: "https://github.com/OpenStreetEditor/OpenStreetEditor"),
        ])
        tableData.append(support)
        let osmText = "Map data (c) Openstreetmap contributors"
        let glText = "Map rendering by GLMap"
        let osmiumText = "Data conversion by Osmium"
        let josmText = "Presets and images from JOSM"
        let second = SettingsTableData(name: "Thanks", items: [
            SettingsCellData(icon: "osmIcon", text: osmText, link: "https://www.openstreetmap.org/"),
            SettingsCellData(icon: "globusIcon", text: glText, link: "https://globus.software/"),
            SettingsCellData(icon: "osmiumIcon", text: osmiumText, link: "https://osmcode.org/"),
            SettingsCellData(icon: "josmIcon", text: josmText, link: "https://josm.openstreetmap.de/"),
        ])
        tableData.append(second)
        let licenseText = "GPLv3"
        let third = SettingsTableData(name: "License", items: [
            SettingsCellData(icon: "gnuIcon", text: licenseText, link: "https://www.gnu.org/licenses/gpl-3.0.html"),
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
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
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
        guard indexPath.section == 0 else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        switch indexPath.row {
        case 0:
            let vc = AuthViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = QuickGuideViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            return
        }
    }
    
    func tableView(_: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let data = tableData[indexPath.section].items[indexPath.row]
        guard let url = URL(string: data.link) else { return }
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true, completion: nil)
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
        if indexPath.section == 0 {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = .detailButton
        }
        return cell
    }
}
