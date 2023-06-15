//
//  PropertiesTable.swift
//  OSM editor
//
//  Created by Arkadiy on 26.02.2023.
//

import Foundation
import UIKit

//  MARK: SOME UI ELEMENTS

// DrawButton on MapViewController
class DrawButton: UIButton {
    var isActive = false {
        didSet {
            if isActive {
                backgroundColor = .systemGray3
            } else {
                backgroundColor = .white
            }
        }
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
        if indicator.isHidden == false {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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

struct InfoCellData {
    let icon: String?
    let text: String
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

    lazy var toolbar: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemBlue, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        let enterButton = UIButton()
        enterButton.setTitle("Enter", for: .normal)
        enterButton.setTitleColor(.systemBlue, for: .normal)
        enterButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        enterButton.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(cancelButton)
        stack.addArrangedSubview(enterButton)
        stack.distribution = .fillEqually
        stack.backgroundColor = .systemGray5
        return stack
    }()
    
    @objc func doneButtonTapped() {
        guard let clouser = callbackClosure,
              let key = keyField.text,
              let value = valueField.text else { return }
        clouser([key: value])
    }
    
    @objc func cancelButtonTapped() {
        guard let clouser = callbackClosure else { return }
        clouser([:])
    }
    
    var callbackClosure: (([String: String]) -> Void)?
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
        backgroundColor = .systemBackground
        alpha = 0.95
    }
    
    func setupConstrains() {
        addSubview(keyField)
        addSubview(valueField)
        addSubview(toolbar)
        addSubview(messageLabel)
        NSLayoutConstraint.activate([
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolbar.leftAnchor.constraint(equalTo: leftAnchor),
            toolbar.rightAnchor.constraint(equalTo: rightAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 50),
            keyField.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
            keyField.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
            keyField.bottomAnchor.constraint(equalTo: valueField.topAnchor, constant: -20),
            valueField.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
            valueField.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
            valueField.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(equalTo: keyField.topAnchor, constant: -20),
            messageLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
            messageLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
        ])
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

// Custom button for download button on the map
class DownloadButton: UIButton {
    let circle: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.isHidden = true
        view.backgroundColor = .systemGreen
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupConstrains()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstrains() {
        addSubview(circle)
        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: 12),
            circle.heightAnchor.constraint(equalToConstant: 12),
            circle.centerXAnchor.constraint(equalTo: rightAnchor, constant: -8),
            circle.centerYAnchor.constraint(equalTo: topAnchor, constant: 8),
        ])
    }
}

//  Custom button for switching to the controller of saved objects
class SavedObjectButton: UIButton {
    private let circle: UIView = {
        let view = UIView()
        let counts = AppSettings.settings.savedObjects.count + AppSettings.settings.deletedObjects.count
        if counts == 0 {
            view.isHidden = true
        } else {
            view.isHidden = false
            view.backgroundColor = .systemRed
        }
        view.layer.cornerRadius = 9
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.text = String(AppSettings.settings.savedObjects.count + AppSettings.settings.deletedObjects.count)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var lastCount = AppSettings.settings.savedObjects.count + AppSettings.settings.deletedObjects.count

    init() {
        super.init(frame: .zero)
        setupConstrains()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstrains() {
        addSubview(circle)
        addSubview(label)
        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: 18),
            circle.heightAnchor.constraint(equalToConstant: 18),
            circle.centerXAnchor.constraint(equalTo: rightAnchor, constant: -3),
            circle.centerYAnchor.constraint(equalTo: topAnchor, constant: 3),
            label.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
        ])
    }
    
    // Method update count and of saved, created and deleted objects
    func update() {
        let counts = AppSettings.settings.savedObjects.count + AppSettings.settings.deletedObjects.count
        guard lastCount != counts else { return }
        if lastCount == 0 {
            circle.isHidden = false
        }
        lastCount = counts
        UIView.animate(withDuration: 0.4, animations: {
            self.circle.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.label.transform = CGAffineTransform(rotationAngle: -.pi)
        }) { _ in
            UIView.animate(withDuration: 0.4) {
                self.circle.transform = .identity
                self.label.transform = .identity
            } completion: { _ in
                if counts == 0 {
                    self.circle.isHidden = true
                    self.label.text = nil
                } else {
                    self.circle.backgroundColor = .systemRed
                    self.label.text = String(counts)
                }
            }
        }
    }
}

//  Custom cell for a tag value selection controller that allows multiple values
class SelectValuesCell: UITableViewCell {
    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var checkBox: CheckBox = {
        let checkBox = CheckBox()
        checkBox.isChecked = false
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        return checkBox
    }()
    
    func setupConstrains() {
        contentView.addSubview(label)
        contentView.addSubview(checkBox)
        NSLayoutConstraint.activate([
            checkBox.rightAnchor.constraint(equalTo: rightAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 50),
            checkBox.heightAnchor.constraint(equalTo: heightAnchor),
            checkBox.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.rightAnchor.constraint(equalTo: checkBox.leftAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            label.topAnchor.constraint(equalTo: topAnchor),
        ])
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isUserInteractionEnabled = true
        setupConstrains()
    }
        
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        checkBox.isChecked = false
        label.text = nil
    }
}

class BulbButton: UIButton {
    let button: UIButton = {
        let but = UIButton()
        but.translatesAutoresizingMaskIntoConstraints = false
        return but
    }()

    var id: Int?
}

//  The button that is used to select the tag values from the list. Used on the tag editing controller and ItemVC
class SelectButton: UIButton {
    var selectClosure: ((String) -> Void)?
    var key: String?
    var values: [String] = []
}

//  Custom UITextField for entering the text value of the tag. Use in ItemVC and EditObjectVC
class ValueField: UITextField, UITextFieldDelegate {
    var key: String?
    var indexPath: IndexPath?
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
