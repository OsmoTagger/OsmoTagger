//
//  AuthViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 12.04.2023.
//

import UIKit
import SafariServices

//  Authorization ViewController
class AuthViewController: SheetViewController {
    let removeLabel = UILabel()
    let toggle = UISwitch()
    let authResult = AuthResultView()
    let userView = UserInfoView()
    
    var flexibleSpace = UIBarButtonItem()
    var loginButton = UIBarButtonItem()
    var signOutButton = UIBarButtonItem()
    var checkButton = UIBarButtonItem()
    
    deinit {
        AppSettings.settings.userInfoClouser = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
//      Set buttons
        flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        loginButton = UIBarButtonItem(title: "Login", style: .done, target: self, action: #selector(tapAuthButton))
        signOutButton = UIBarButtonItem(title: "Sign out", style: .plain, target: self, action: #selector(tapSignout))
        checkButton = UIBarButtonItem(title: "Check", style: .plain, target: self, action: #selector(tapCheckButton))
        navigationController?.setToolbarHidden(false, animated: false)
        
//      Closure, which is performed upon successful authorization to upload the user's nickname. It is deinitialized when closed.
        AppSettings.settings.userInfoClouser = { [weak self] userInfo in
            guard let self = self else { return }
            self.setUserInfoView(user: userInfo)
        }
        
        setTitleView()
        updateToolBar()
        setWarningLabel()
        setServerTogle()
        setAuthResult()
        authResult.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewDidDisappear(_: Bool) {}
    
    //  The method updates the buttons depending on the authorization result.
    func updateToolBar() {
        if AppSettings.settings.token == nil {
            toolbarItems = [flexibleSpace, loginButton, flexibleSpace]
        } else {
            toolbarItems = [flexibleSpace, signOutButton, flexibleSpace, checkButton, flexibleSpace]
        }
    }
    
    func setWarningLabel() {
        let text = """
        OsmoTagger uses OAuth 2.0 authentication, and does not have access to a login and password for authorization on the server openstreetmap.org.
        """
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        let removeText = "Remove OsmoTagger from authorized OAuth 2.0 applications"
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        let underlinedText = NSAttributedString(string: removeText, attributes: underlineAttribute)
        removeLabel.isUserInteractionEnabled = true
        removeLabel.textAlignment = .center
        removeLabel.numberOfLines = 0
        removeLabel.attributedText = underlinedText
        removeLabel.textColor = .systemBlue
        let removeTap = UITapGestureRecognizer(target: self, action: #selector(tapRemove))
        removeTap.delegate = self
        removeLabel.addGestureRecognizer(removeTap)
        
        removeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(removeLabel)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30),
            label.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30),
            
            removeLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            removeLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30),
            removeLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30),
        ])
    }
    
    @objc private func tapRemove() {
        let link = AppSettings.settings.server + "/oauth2/applications"
        guard let url = URL(string: link) else {return}
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }
    
    func setServerTogle() {
        toggle.isOn = AppSettings.settings.isDevServer
        toggle.addTarget(self, action: #selector(isSwitched), for: .valueChanged)
        view.addSubview(toggle)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        
        let leftLable = UILabel()
        leftLable.text = "Production server"
        leftLable.textAlignment = .right
        view.addSubview(leftLable)
        leftLable.translatesAutoresizingMaskIntoConstraints = false
        
        let rightLable = UILabel()
        rightLable.text = "Developer server"
        rightLable.textAlignment = .left
        view.addSubview(rightLable)
        rightLable.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([toggle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     toggle.topAnchor.constraint(equalTo: removeLabel.bottomAnchor, constant: 25),
                                     rightLable.centerYAnchor.constraint(equalTo: toggle.centerYAnchor),
                                     rightLable.leftAnchor.constraint(equalTo: toggle.rightAnchor, constant: 5),
                                     leftLable.centerYAnchor.constraint(equalTo: toggle.centerYAnchor),
                                     leftLable.rightAnchor.constraint(equalTo: toggle.leftAnchor, constant: -5)])
    }
    
    func setAuthResult() {
        view.addSubview(authResult)
        NSLayoutConstraint.activate([
            authResult.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authResult.topAnchor.constraint(equalTo: toggle.bottomAnchor, constant: 25),
            authResult.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 25),
            authResult.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25),
        ])
    }
    
    func setUserInfoView(user: OSMUserInfo) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.userView.removeFromSuperview()
            self.userView.idLabel.text = "User id: \(String(user.user.id))"
            self.userView.nickLabel.text = "User name: \(user.user.display_name)"
            self.userView.timeLabel.text = "Account created: \(user.user.account_created)"
            self.userView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.userView)
            NSLayoutConstraint.activate([
                self.userView.topAnchor.constraint(equalTo: self.authResult.bottomAnchor, constant: 25),
                self.userView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                self.userView.leftAnchor.constraint(equalTo: self.authResult.leftAnchor),
            ])
        }
    }
    
    //  Tap on switch
    @objc func isSwitched(sender: UISwitch) {
        AppSettings.settings.isDevServer = sender.isOn
        authResult.update()
        updateToolBar()
        userView.removeFromSuperview()
    }

    @objc func tapAuthButton() {
        let indicator = showIndicator()
        Task {
            do {
                try await OsmClient().checkAuth()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.authResult.update()
                    self.updateToolBar()
                }
            } catch {
                let message = error as? String ?? "Error while auth"
                showAction(message: message, addAlerts: [])
            }
            self.removeIndicator(indicator: indicator)
        }
    }
    
    @objc func tapCheckButton() {
        Task {
            let indicator = showIndicator()
            do {
                let userInfo = try await OsmClient().getUserInfo()
                setUserInfoView(user: userInfo)
            } catch {
                let message = error as? String ?? "Error check user info"
                showAction(message: message, addAlerts: [])
            }
            removeIndicator(indicator: indicator)
        }
    }
    
    @objc func tapSignout() {
        AppSettings.settings.token = nil
        authResult.update()
        userView.removeFromSuperview()
        updateToolBar()
    }
    
    func setTitleView() {
        let titleView = SettingsTitleView()
        titleView.icon.image = UIImage(systemName: "person.crop.circle")
        titleView.label.text = "Authorization"
        titleView.addConstraints([
            titleView.heightAnchor.constraint(equalToConstant: 30),
        ])
        navigationItem.titleView = titleView
    }
}

