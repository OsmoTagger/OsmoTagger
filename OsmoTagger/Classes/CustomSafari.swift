//
//  CustomSafari.swift
//  OpenStreetEditor
//
//  Created by Аркадий Торвальдс on 26.07.2023.
//

import Foundation
import SafariServices
import UIKit

//  Custom SFSafariViewController for calling closure when closing. Use in EditObjectVC
class CustomSafari: SFSafariViewController {
    var callbackClosure: EmptyBlock?
    
    override func viewDidDisappear(_: Bool) {
        guard let clouser = callbackClosure else { return }
        clouser()
    }
}
