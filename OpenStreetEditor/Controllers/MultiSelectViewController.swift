//
//  SelectObjectViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 28.03.2023.
//

import Foundation
import UIKit

//  The controller that is called when you click on the tag value selection button, which allows you to save multiple values, for example sports=swimming;volleyball.
class MultiSelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var values: [String]
    let key: String
    var button: MultiSelectBotton
    
    var tableView = UITableView()
    var cellId = "cell"
    
    var callbackClosure: ((MultiSelectBotton) -> Void)?
    
    init(values: [String], key: String, button: MultiSelectBotton) {
        self.values = values
        self.key = key
        self.button = button
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        setTableView()
        setCloseButton()
    }
    
    override func viewDidDisappear(_: Bool) {}
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return values.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellFail = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cellFail.textLabel?.text = "Point data loading error"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SelectValuesCell else { return cellFail }
        cell.backgroundColor = .backColor0
        let value = values[indexPath.row]
        cell.label.text = value
        if let inputValues = AppSettings.settings.newProperties[key] {
            if inputValues.contains(value) {
                cell.checkBox.isChecked = true
            } else {
                cell.checkBox.isChecked = false
            }
        } else {
            cell.checkBox.isChecked = false
        }
        cell.checkBox.indexPath = indexPath
        cell.checkBox.addTarget(self, action: #selector(tapCheckBox), for: .touchUpInside)
        return cell
    }
    
    @objc func tapCheckBox(sender: CheckBox) {
        sender.isChecked = !sender.isChecked
        if sender.isChecked {
            if var inputValuesString = AppSettings.settings.newProperties[key] {
                inputValuesString += ";" + values[sender.indexPath.row]
                AppSettings.settings.newProperties[key] = inputValuesString
            } else {
                AppSettings.settings.newProperties[key] = values[sender.indexPath.row]
            }
        } else {
            if var inputValuesString = AppSettings.settings.newProperties[key] {
                var inputValues = inputValuesString.components(separatedBy: ";")
                guard let i = inputValues.firstIndex(of: values[sender.indexPath.row]) else { return }
                inputValues.remove(at: i)
                if inputValues.count == 0 {
                    AppSettings.settings.newProperties.removeValue(forKey: key)
                } else if inputValues.count == 1 {
                    AppSettings.settings.newProperties[key] = inputValues[0]
                } else {
                    inputValuesString = inputValues[0]
                    for i in 1 ... inputValues.count - 1 {
                        let value = inputValues[i]
                        inputValuesString += ";" + value
                    }
                    AppSettings.settings.newProperties[key] = inputValuesString
                }
            }
        }
    }
    
    func setCloseButton() {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(systemName: "xmark")?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        closeButton.addTarget(self, action: #selector(dismissController), for: .touchUpInside)
        closeButton.layer.cornerRadius = 15
        closeButton.backgroundColor = .systemGray3
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([closeButton.widthAnchor.constraint(equalToConstant: 30),
                                     closeButton.heightAnchor.constraint(equalToConstant: 30),
                                     closeButton.centerXAnchor.constraint(equalTo: view.rightAnchor, constant: -10),
                                     closeButton.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 10)])
    }
    
    @objc func dismissController() {
        guard let callbackClosure = callbackClosure else {
            return
        }
        callbackClosure(button)
        dismiss(animated: true, completion: nil)
    }
    
    func setTableView() {
        tableView.rowHeight = 50
        tableView.layer.borderColor = UIColor.gray.cgColor
        tableView.layer.borderWidth = 2
        tableView.layer.cornerRadius = 4
        tableView.separatorColor = .serparatorColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SelectValuesCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
    }
}
