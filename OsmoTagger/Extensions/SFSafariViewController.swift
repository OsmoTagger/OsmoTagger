//
//  SFSafariViewController.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 18.09.2023.
//

import Foundation
import UIKit
import SafariServices

extension SFSafariViewController {
    
    static func present(parent: UIViewController, url: String) {
        guard let url = URL(string: url) else {return}
        let vc = SFSafariViewController(url: url)
        parent.present(vc, animated: true)
    }
    
}
