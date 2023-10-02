//
//  OverpassViewController.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 03.10.2023.
//

import UIKit

class OverpassViewController: ScrollViewController {
    
    private let spacing: CGFloat = 10
    
    let indicator = UIActivityIndicatorView()
    
    let field = UITextView()
    let label = UILabel()
    let sendButton = UIButton(configuration: .borderedProminent())
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Overpass API"
        view.backgroundColor = .systemBackground
        
        setRightButtons()
        setTextView()
        setLabel()
        setButtons()
        setLabels()
    }
    
    // MARK: ACTIONS
    
    @objc private func tapHelp() {
        print("tap")
    }
    
    // MARK: ELEMENTS
    
    private func setLabels() {
        let infoLabel = UILabel()
        infoLabel.text = "The Overpass API allows you to retrieve OpenStreetMap data with specific tags or within a particular region."
        infoLabel.numberOfLines = 0
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(infoLabel)
        
        let helpLabel = UILabel()
        let labelText = "Overpass API help"
        helpLabel.font = .systemFont(ofSize: 14)
        let attributedString = NSMutableAttributedString(string: labelText)
        let range = NSRange(location: 0, length: labelText.count)
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: range)
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        helpLabel.attributedText = attributedString
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHelp))
        tap.delegate = self
        helpLabel.addGestureRecognizer(tap)
        scrollView.addSubview(helpLabel)
        
        NSLayoutConstraint.activate([
            infoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            infoLabel.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: spacing * 2),
            infoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            
            helpLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            helpLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: spacing),
            helpLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            
            scrollView.bottomAnchor.constraint(equalTo: helpLabel.bottomAnchor)
        ])
    }
    
    private func setButtons() {
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(sendButton)
        NSLayoutConstraint.activate([
            sendButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            sendButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: spacing * 2),
            sendButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setRightButtons() {
        indicator.style = .medium
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        let barIndicator = UIBarButtonItem(customView: indicator)
        rightButtons = [barIndicator]
    }
    
    private func setLabel() {
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            label.topAnchor.constraint(equalTo: field.bottomAnchor, constant: spacing * 2),
            label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
        ])
    }
    
    private func setTextView() {
        field.layer.borderColor = UIColor.systemGray.cgColor
        field.layer.borderWidth = 2
        field.layer.cornerRadius = 4
        field.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            field.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: spacing),
            field.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            field.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
}

// MARK: UIGestureRecognizerDelegate
extension OverpassViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool { return true }
}
