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
    var inputValue: String?
    let key: String
    
    var tableView = UITableView()
    var cellId = "cell"
    
    var callbackClosure: ((String?) -> Void)?
    
    init(values: [String], key: String, inputValue: String?) {
        self.values = values
        self.inputValue = inputValue
        self.key = key
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        title = "Choose the required values"
        view.backgroundColor = .systemBackground
        setTableView()
    }
    
    override func viewDidDisappear(_: Bool) {
        if let clouser = callbackClosure {
            clouser(inputValue)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return values.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellFail = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cellFail.textLabel?.text = "Point data loading error"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SelectValuesCell else { return cellFail }
        let value = values[indexPath.row]
        cell.label.text = value
        if let inputValues = inputValue {
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
            if var inputValuesString = inputValue {
                inputValuesString += ";" + values[sender.indexPath.row]
                inputValue = inputValuesString
            } else {
                inputValue = values[sender.indexPath.row]
            }
        } else {
            if var inputValuesString = inputValue {
                var inputValues = inputValuesString.components(separatedBy: ";")
                guard let i = inputValues.firstIndex(of: values[sender.indexPath.row]) else { return }
                inputValues.remove(at: i)
                if inputValues.count == 0 {
                    inputValue = nil
                } else if inputValues.count == 1 {
                    inputValue = inputValues[0]
                } else {
                    inputValuesString = inputValues[0]
                    for i in 1 ... inputValues.count - 1 {
                        let value = inputValues[i]
                        inputValuesString += ";" + value
                    }
                    inputValue = inputValuesString
                }
            }
        }
    }
    
    func setTableView() {
        tableView.rowHeight = 50
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
