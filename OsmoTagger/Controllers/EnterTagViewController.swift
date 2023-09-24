//
//  EnterTagViewController.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 24.09.2023.
//

import UIKit

class EnterTagViewController: SheetViewController {
    
    var key: String?
    var value: String?
    
    private let addTagView = AddTagManuallyView()
    
    init(key: String?, value: String?) {
        self.key = key
        self.value = value
        super.init()
    }
    
    deinit {
        AppSettings.settings.editableObject = nil
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        
        setAddTagView()
        startEdit()
    }
    
    private func startEdit() {
        if key == nil {
            addTagView.keyField.becomeFirstResponder()
        } else if key != nil {
            addTagView.valueField.becomeFirstResponder()
        }
    }
    
    private func setAddTagView() {
        addTagView.keyField.text = key
        addTagView.valueField.text = value
        
        addTagView.callbackClosure = { [weak self] tag in
            guard let self = self else {return}
            for (key, value) in tag {
                if key == "" || value == "" {
                    let text = """
                    Key or value cannot be empty!
                    Key = "\(key)"
                    Value = "\(value)"
                    """
                    Alert.showAction(parent: self, message: text, addAlerts: [])
                    return
                }
            }
            self.view.endEditing(true)
            if let navVC = self.navigationController as? CategoryNavigationController {
                navVC.objectProperties = tag
            }
            self.navigationController?.dismiss(animated: true)
        }
        
        view.addSubview(addTagView)
        NSLayoutConstraint.activate([
            addTagView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            addTagView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            addTagView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            addTagView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
}
