//
//  BottomDrawer.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 20.08.2023.
//

import Foundation
import UIKit


class BottomDrawer: UIView {
    private var tagsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private lazy var closeBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .systemGray
        button.layer.cornerRadius = buttonHeight / 2
        button.backgroundColor = .systemGray4
        button.addTarget(self, action: #selector(tapCloseButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private lazy var stack: UIStackView = {
        let stackView = UIStackView()
        stackView.backgroundColor = .systemGray4
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        let editBtn = UIButton()
        editBtn.setTitle("Edit object", for: .normal)
        editBtn.setTitleColor(.systemBlue, for: .normal)
        editBtn.addTarget(self, action: #selector(tapEditBtn), for: .touchUpInside)
        let deleteBtn = UIButton()
        deleteBtn.setTitle("Delete object", for: .normal)
        deleteBtn.setTitleColor(.systemBlue, for: .normal)
        deleteBtn.addTarget(self, action: #selector(tapDeleteButton), for: .touchUpInside)
        stackView.addArrangedSubview(deleteBtn)
        stackView.addArrangedSubview(editBtn)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    private var stackBackView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var object: OSMAnyObject {
        didSet {
            AppSettings.settings.editableObject = object.vector
        }
    }
    
    private let buttonHeight: CGFloat = 24
    private let spacing: CGFloat = 10
    private let stackHeight: CGFloat = 50
    private var minHeight: CGFloat {
        return stackHeight + buttonHeight + 2 * spacing + safeAreaInsets.bottom
    }
    var callBack: OSMAnyObjectBlock?
        
    init(object: OSMAnyObject) {
        self.object = object
        AppSettings.settings.editableObject = object.vector
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        layer.cornerRadius = 10
        translatesAutoresizingMaskIntoConstraints = false
        setText()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        UIView.animate(withDuration: 0.1) {
            self.layoutIfNeeded()
            self.alpha = 1.0
        }
    }
        
    @objc private func tapCloseButton() {
        AppSettings.settings.editableObject = nil
        hideView()
    }
    
    @objc private func tapEditBtn() {
        hideView()
        callBack?(object)
    }
    
    @objc private func tapDeleteButton() {
        AppSettings.settings.deletedObjects[object.id] = object
        hideView()
    }
    
    private func hideView() {
        UIView.animate(withDuration: 0.1) {
            self.alpha = 0.0
        }
    }
    
    private func setText() {
        var text: String?
        for tag in object.tag {
            if text == nil {
                text = tag.k + " = " + tag.v
            } else {
                text! += "\n" + tag.k + " = " + tag.v
            }
        }
        tagsLabel.text = text
    }
    
    func updateObject(object: OSMAnyObject) {
        self.object = object
        setText()
        updateConstraints()
    }
    
    private func setupConstrains() {
        addSubview(tagsLabel)
        addSubview(closeBtn)
        addSubview(stackBackView)
        addSubview(stack)
        NSLayoutConstraint.activate([
            tagsLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            tagsLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeBtn.leadingAnchor, constant: -spacing),
            tagsLabel.topAnchor.constraint(equalTo: topAnchor, constant: spacing),
            tagsLabel.bottomAnchor.constraint(equalTo: stack.topAnchor, constant: -spacing),
            
            closeBtn.widthAnchor.constraint(equalToConstant: buttonHeight),
            closeBtn.heightAnchor.constraint(equalToConstant: buttonHeight),
            closeBtn.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -spacing / 2),
            closeBtn.topAnchor.constraint(equalTo: topAnchor, constant: spacing / 2),
            closeBtn.bottomAnchor.constraint(lessThanOrEqualTo: stack.topAnchor, constant: -spacing),
            
            stackBackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackBackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackBackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackBackView.topAnchor.constraint(equalTo: stack.topAnchor),
            
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalToConstant: stackHeight)
        ])
    }
    
    func setupView(parent: UIView) {
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            self.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ])
    }
}
