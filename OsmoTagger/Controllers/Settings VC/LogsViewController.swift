//
//  LogsViewController.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 20.09.2023.
//

import UIKit

class LogsViewController: UIViewController {
    var tableView = UITableView()
    let cellId = "cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "App logs"
        view.backgroundColor = .systemBackground
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let item = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(tapShare))
        toolbarItems = [flexibleSpace, item, flexibleSpace]
        
        setTableView()
    }
    
    override func viewWillAppear(_: Bool) {
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_: Bool) {
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_: Bool) {
        let last = AppSettings.settings.logs.count - 1
        let lastIndexPath = IndexPath(row: last, section: 0)
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
    }
    
    private func setTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StretchableCell.self, forCellReuseIdentifier: cellId)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    @objc private func tapShare() {
        let zipURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logs.zip")
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: AppSettings.settings.logs, requiringSecureCoding: false)
            try data.write(to: zipURL, options: .atomic)
        } catch {
            Log("Error archived data: \(error)")
            Alert.showAlert("Error archived data: \(error)")
            return
        }
        let actVC = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
        present(actVC, animated: true, completion: {
            do {
                try FileManager.default.removeItem(at: zipURL)
            } catch {
                Alert.showAlert("Error remove logs.zip \(error)")
                Log("Error remove logs.zip \(error)")
            }
        })
    }
}

extension LogsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return AppSettings.settings.logs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? StretchableCell else {
            return UITableViewCell()
        }
        let log = AppSettings.settings.logs[indexPath.row]
        cell.configure(log)
        return cell
    }
}
