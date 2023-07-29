//
//  ScreenSettingsViewController.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 27.07.2023.
//

import UIKit

// Main screen settings controller
class ScreenSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()
    let cellId = "cell"
    var tableData: [ScreenSettingsCellData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "Main screen"
        fillData()
        setTableView()
    }
    
    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ScreenSettingsCell else { return }
        let newValue = cell.toogle.isOn
        switch indexPath.row {
        case 0:
            AppSettings.settings.mapButtonsIsHidden = newValue
        case 1:
            AppSettings.settings.sourceFrameisHidden = newValue
        default:
            return
        }
        fillData()
        tableView.reloadData()
    }
        
    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? ScreenSettingsCell else {
            let cellFail = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
            cellFail.textLabel?.text = "Point data loading error"
            return cellFail
        }
        let data = tableData[indexPath.row]
        cell.icon.image = UIImage(named: data.icon)
        cell.mainLabel.text = data.mainText
        cell.toogle.isOn = !data.toogleIsOn
        return cell
    }
    
    func fillData() {
        tableData = [ScreenSettingsCellData(icon: "mapButtons.png", mainText: "Show navigation buttons", toogleIsOn: AppSettings.settings.mapButtonsIsHidden),
                     ScreenSettingsCellData(icon: "sourceFrame.png", mainText: "Show the boundary of loaded data", toogleIsOn: AppSettings.settings.sourceFrameisHidden)]
    }
    
    func setTableView() {
        tableView.rowHeight = 160
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ScreenSettingsCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
