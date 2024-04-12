//
//  AuthViewController.swift
//  OSM editor
//
//  Created by Arkadiy on 12.04.2023.
//

import SafariServices
import UIKit

//  Authorization ViewController
class AuthViewController: SheetViewController {
    let topLabel = UILabel()
    let toggle = UISwitch()
    let authResult = AuthResultView()
    let userView = UserInfoView()
    
    var flexibleSpace = UIBarButtonItem()
    var loginButton = UIBarButtonItem()
    var signOutButton = UIBarButtonItem()
    var checkButton = UIBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        // Set buttons
        flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        loginButton = UIBarButtonItem(title: "Login", style: .done, target: self, action: #selector(tapAuthButton))
        signOutButton = UIBarButtonItem(title: "Sign out", style: .plain, target: self, action: #selector(tapSignout))
        checkButton = UIBarButtonItem(title: "Check", style: .plain, target: self, action: #selector(tapCheckButton))
        navigationController?.setToolbarHidden(false, animated: false)
        
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
        topLabel.text = text
        topLabel.textAlignment = .center
        topLabel.numberOfLines = 0
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topLabel)
        
        let guide = view.safeAreaLayoutGuide
    
        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: guide.topAnchor),
            topLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 30),
            topLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -30),
//            topLabel.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -30),
        ])
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
                                     toggle.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 25),
                                     rightLable.centerYAnchor.constraint(equalTo: toggle.centerYAnchor),
                                     rightLable.leadingAnchor.constraint(equalTo: toggle.trailingAnchor, constant: 5),
                                     leftLable.centerYAnchor.constraint(equalTo: toggle.centerYAnchor),
                                     leftLable.trailingAnchor.constraint(equalTo: toggle.leadingAnchor, constant: -5)])
    }
    
    func setAuthResult() {
        view.addSubview(authResult)
        NSLayoutConstraint.activate([
            authResult.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authResult.topAnchor.constraint(equalTo: toggle.bottomAnchor, constant: 25),
            authResult.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            authResult.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
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
                self.userView.leadingAnchor.constraint(equalTo: self.authResult.leadingAnchor),
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
                try await OsmClient.client.checkAuth()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.authResult.update()
                    self.updateToolBar()
                }
                Alert.showAlert("Authentication successful", isBad: false)
                let userInfo = try await OsmClient.client.getUserInfo()
                setUserInfoView(user: userInfo)
            } catch {
                let message = error as? String ?? "Error while auth"
                Alert.showAlert(message)
            }
            self.removeIndicator(indicator: indicator)
        }
    }
    
    @objc func tapCheckButton() {
        Task {
            let indicator = showIndicator()
            do {
                let userInfo = try await OsmClient.client.getUserInfo()
                setUserInfoView(user: userInfo)
            } catch {
                let message = error as? String ?? "Error check user info"
                Alert.showAlert(message)
            }
            removeIndicator(indicator: indicator)
        }
    }
    
    @objc func tapSignout() {
        AppSettings.settings.token = nil
        authResult.update()
        userView.removeFromSuperview()
        updateToolBar()
        Alert.showAlert("You have logged out")
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

extension AuthViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool { return true }
}
