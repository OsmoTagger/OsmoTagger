//
//  TestViewController.swift
//  OpenStreetEditor
//
//  Created by Arkadiy on 08.06.2023.
//

import UIKit

class TestViewController: UIViewController {
    var tableView = UITableView()
    let cellId = "cell"
    var tableData: [SettingsCellData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fillData()
        setTableView()
    }
    
    func fillData() {
        for category in AppSettings.settings.categories {
            let data = SettingsCellData(icon: category.icon, text: category.name, link: "")
            tableData.append(data)
            for item in category.item {
                guard let icon = item.icon else { continue }
                let data = SettingsCellData(icon: icon, text: item.name, link: "")
                tableData.append(data)
            }
            for group in category.group {
                let data = SettingsCellData(icon: group.icon, text: group.name, link: "")
                tableData.append(data)
                for item in group.item {
                    guard let icon = item.icon else { continue }
                    let data = SettingsCellData(icon: icon, text: item.name, link: "")
                    tableData.append(data)
                }
            }
        }
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
}

extension TestViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return tableData.count
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SimpleCell else {
            let cellFail = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
            cellFail.textLabel?.text = "Point data loading error"
            return cellFail
        }
        let data = tableData[indexPath.row]
        cell.icon.icon.image = UIImage(named: data.icon)
        cell.label.text = data.text
        return cell
    }
}
