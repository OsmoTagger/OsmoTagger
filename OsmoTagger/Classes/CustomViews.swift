//
//  CustomViews.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
//

import Foundation
import UIKit

class RightIconView: UIView {
    var backView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    var icon: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(backView)
        addSubview(icon)
        NSLayoutConstraint.activate([
            backView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5),
            backView.widthAnchor.constraint(equalToConstant: 38),
            backView.heightAnchor.constraint(equalToConstant: 38),
            backView.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.centerXAnchor.constraint(equalTo: backView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
        ])
    }
}

class IconView: UIView {
    var backView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 19
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    var icon: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(backView)
        addSubview(icon)
        let iconWidth = icon.image?.size.width ?? 25
        let iconHeight = icon.image?.size.height ?? 25
        NSLayoutConstraint.activate([
            backView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5),
            backView.widthAnchor.constraint(equalToConstant: 38),
            backView.heightAnchor.constraint(equalToConstant: 38),
            backView.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.centerXAnchor.constraint(equalTo: backView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: iconWidth),
            icon.heightAnchor.constraint(equalToConstant: iconHeight),
        ])
    }
}

// Custom download indicator for MapVC
class DownloadIndicatorView: UIView {
    private let indicator: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    private func setupConstrains() {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default)
        let image = UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: imageConfig)?.withTintColor(.black, renderingMode: .alwaysOriginal)
        indicator.image = image
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    func startAnimating() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if indicator.isHidden == false {
                return
            }
            self.indicator.isHidden = false
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.toValue = NSNumber(value: Double.pi * 2)
            rotationAnimation.duration = 1.3
            rotationAnimation.repeatCount = Float.infinity
            self.indicator.layer.add(rotationAnimation, forKey: "rotationAnimation")
        }
    }
    
    func stopAnimating() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.indicator.layer.removeAnimation(forKey: "rotationAnimation")
            self.indicator.isHidden = true
        }
    }
}

//  View for displaying user data
class UserInfoView: UIView {
    var idIcon: UIImageView = {
        let image = UIImageView(image: UIImage(systemName: "number.circle"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var idLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var nickIcon: UIImageView = {
        let image = UIImageView(image: UIImage(systemName: "person.crop.circle"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var nickLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var timeIcon: UIImageView = {
        let image = UIImageView(image: UIImage(systemName: "clock"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(idIcon)
        addSubview(idLabel)
        addSubview(nickIcon)
        addSubview(nickLabel)
        addSubview(timeIcon)
        addSubview(timeLabel)
        NSLayoutConstraint.activate([
            idIcon.topAnchor.constraint(equalTo: topAnchor),
            idIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            idIcon.widthAnchor.constraint(equalToConstant: 24),
            idIcon.heightAnchor.constraint(equalToConstant: 24),
            idLabel.leftAnchor.constraint(equalTo: idIcon.rightAnchor, constant: 5),
            idLabel.centerYAnchor.constraint(equalTo: idIcon.centerYAnchor),
            idLabel.rightAnchor.constraint(equalTo: rightAnchor),
            nickIcon.topAnchor.constraint(equalTo: idIcon.bottomAnchor, constant: 5),
            nickIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            nickIcon.widthAnchor.constraint(equalToConstant: 24),
            nickIcon.heightAnchor.constraint(equalToConstant: 24),
            nickLabel.leftAnchor.constraint(equalTo: nickIcon.rightAnchor, constant: 5),
            nickLabel.centerYAnchor.constraint(equalTo: nickIcon.centerYAnchor),
            nickLabel.rightAnchor.constraint(equalTo: rightAnchor),
            timeIcon.topAnchor.constraint(equalTo: nickIcon.bottomAnchor, constant: 5),
            timeIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            timeIcon.widthAnchor.constraint(equalToConstant: 24),
            timeIcon.heightAnchor.constraint(equalToConstant: 24),
            timeLabel.leftAnchor.constraint(equalTo: timeIcon.rightAnchor, constant: 5),
            timeLabel.centerYAnchor.constraint(equalTo: timeIcon.centerYAnchor),
            timeLabel.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }
}

//  View with the authorization result on the authorization controller
class AuthResultView: UIView {
    var icon: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18)
        label.baselineAdjustment = .alignCenters
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
        update()
    }
    
    func setupConstrains() {
        addSubview(icon)
        addSubview(label)
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 24),
            icon.widthAnchor.constraint(equalToConstant: 24),
            label.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 5),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }
    
    //  Method update view after authorization
    func update() {
        var server = ""
        if AppSettings.settings.isDevServer {
            server = "developer server"
        } else {
            server = "production server"
        }
        if AppSettings.settings.token == nil {
            icon.image = UIImage(named: "cancel")
            label.text = "Authorization on \(server) failed"
        } else {
            icon.image = UIImage(named: "success")
            if let login = AppSettings.settings.userName {
                label.text = "You are logged in to the \(server) as \(login)"
            } else {
                label.text = "Authorization on \(server) success"
            }
        }
    }
}

//  View for manual input of a tag=value pair
class AddTagManuallyView: UIView {
    var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let message = """
        Please, pay attention to character case!
        "Highway" is not equal to "highway".
        """
        label.text = message
        label.numberOfLines = 2
        return label
    }()
    
    var keyField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.clearButtonMode = .always
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.placeholder = "Enter key"
        return field
    }()

    var valueField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.clearButtonMode = .always
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.placeholder = "Enter value"
        return field
    }()

    private lazy var cancelButton: UIButton = {
        let rv = UIButton(configuration: .borderedProminent())
        rv.setTitle("Cancel", for: .normal)
        rv.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()

    private lazy var enterButton: UIButton = {
        let rv = UIButton(configuration: .borderedProminent())
        rv.setTitle("Enter", for: .normal)
        rv.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()
    
    @objc private func doneButtonTapped() {
        guard let key = keyField.text,
              let value = valueField.text else { return }
        addTagClosure([key: value])
        dismissClosure?()
    }
    
    @objc private func cancelButtonTapped() {
        addTagClosure([:])
        dismissClosure?()
    }
    
    var addTagClosure: TagBlock
    var dismissClosure: EmptyBlock?
    var bottomConstraint: NSLayoutConstraint?
    
    init(callback: @escaping TagBlock) {
        addTagClosure = callback
        super.init(frame: .zero)
        setupConstrains()
        backgroundColor = .systemGray4
        alpha = 0.95
        translatesAutoresizingMaskIntoConstraints = false
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              keyboardSize.height > 0 else { return }
        let bottomInsent = window?.safeAreaInsets.bottom ?? 0
        bottomConstraint?.constant = -keyboardSize.height + bottomInsent
    }
    
    @objc private func keyboardWillHide() {
        bottomConstraint?.constant = 0
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstrains() {
        addSubview(messageLabel)
        addSubview(keyField)
        addSubview(valueField)
        addSubview(cancelButton)
        addSubview(enterButton)
        let labelMinHeight: CGFloat = isPad ? 80 : 40
        let spacing: CGFloat = 15
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacing),
            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -spacing),
            cancelButton.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -spacing),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            
            enterButton.leadingAnchor.constraint(equalTo: centerXAnchor, constant: spacing),
            enterButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -spacing),
            enterButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -spacing),
            enterButton.heightAnchor.constraint(equalToConstant: 40),
            
            keyField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacing),
            keyField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -spacing),
            keyField.bottomAnchor.constraint(equalTo: valueField.topAnchor, constant: -spacing),
            keyField.heightAnchor.constraint(greaterThanOrEqualToConstant: labelMinHeight),
            valueField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacing),
            valueField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -spacing),
            valueField.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -spacing),
            valueField.heightAnchor.constraint(greaterThanOrEqualToConstant: labelMinHeight),
            messageLabel.bottomAnchor.constraint(equalTo: keyField.topAnchor, constant: -spacing),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacing),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -spacing),
        ])
    }
    
    static func showAddTagView(key: String?, value: String?, callback: @escaping TagBlock) {
        let addTagView = AddTagManuallyView(callback: callback)
        addTagView.dismissClosure = { [weak addTagView] in
            addTagView?.removeFromSuperview()
        }
        addTagView.keyField.text = key
        addTagView.valueField.text = value
        if key == nil {
            addTagView.keyField.becomeFirstResponder()
        } else {
            addTagView.keyField.isUserInteractionEnabled = false
            addTagView.valueField.becomeFirstResponder()
        }
        #if targetEnvironment(macCatalyst)
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let topViewController = scene.windows.first?.rootViewController else { return }
            var curVC = topViewController
            while let presentedViewController = curVC.presentedViewController {
                curVC = presentedViewController
            }
            curVC.view.addSubview(addTagView)
            NSLayoutConstraint.activate([
                addTagView.leadingAnchor.constraint(equalTo: curVC.view.leadingAnchor),
                addTagView.topAnchor.constraint(equalTo: curVC.view.topAnchor),
                addTagView.trailingAnchor.constraint(equalTo: curVC.view.trailingAnchor),
                addTagView.bottomAnchor.constraint(equalTo: curVC.view.bottomAnchor),
            ])
        #else
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            window.addSubview(addTagView)
            let constraint = addTagView.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor)
            addTagView.bottomConstraint = constraint
            NSLayoutConstraint.activate([
                addTagView.topAnchor.constraint(equalTo: window.topAnchor),
                addTagView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                addTagView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                constraint,
            ])
        #endif
    }
}

//  TitleView for the tag editing controller
class EditTitleView: UIView {
    var icon: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 18)
        label.baselineAdjustment = .alignCenters
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var listIcon: UIImageView = {
        let image = UIImageView(image: UIImage(systemName: "chevron.down"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(icon)
        addSubview(label)
        addSubview(listIcon)
        let iconSize = CGFloat(18)
        let listIconSize = CGFloat(18)
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: iconSize),
            icon.widthAnchor.constraint(equalToConstant: iconSize),
            listIcon.rightAnchor.constraint(equalTo: rightAnchor, constant: -7),
            listIcon.heightAnchor.constraint(equalToConstant: listIconSize),
            listIcon.widthAnchor.constraint(equalToConstant: listIconSize),
            listIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 5),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.rightAnchor.constraint(equalTo: listIcon.leftAnchor, constant: -7),
        ])
    }
}

class SettingsTitleView: UIView {
    var icon: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 18)
        label.baselineAdjustment = .alignCenters
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(icon)
        addSubview(label)
        let iconSize = CGFloat(18)
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: iconSize),
            icon.widthAnchor.constraint(equalToConstant: iconSize),
            label.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 5),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -7),
        ])
    }
}

class CheckBox: UIButton {
    let checkedImage = UIImage(systemName: "square")
    let uncheckedImage = UIImage(systemName: "checkmark.square")
    
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                setImage(uncheckedImage?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal), for: .normal)
            } else {
                setImage(checkedImage?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal), for: .normal)
            }
        }
    }
    
    var indexPath = IndexPath()
}

// View for entering a comment for a changeset.
class ChangesetCommentView: UIView {
    private lazy var label: UILabel = {
        let rv = UILabel()
        rv.text = "Comment"
        rv.backgroundColor = .systemBackground
        rv.font = UIFont.systemFont(ofSize: 14)
        rv.textColor = .systemGray
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()

    lazy var field: UITextField = {
        let rv = UITextField()
        rv.layer.borderWidth = 2
        rv.layer.cornerRadius = 5
        rv.clearButtonMode = .always
        rv.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 5))
        rv.leftViewMode = .always
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()
    
    // Since UITableView doesn't work properly with autolayout, views are added using frames. Only the height is specified.
    convenience init() {
        self.init(frame: .zero)
        frame.size.height = 50
        setupConstrains()
    }
    
    private func setupConstrains() {
        addSubview(field)
        addSubview(label)
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            field.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.95),
            field.centerXAnchor.constraint(equalTo: centerXAnchor),
            field.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            
            label.centerYAnchor.constraint(equalTo: field.topAnchor),
            label.leadingAnchor.constraint(equalTo: field.leadingAnchor, constant: 10),
        ])
    }
}
