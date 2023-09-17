//
//  UIColor.swift
//  OpenStreetEditor
//
//  Created by Arkadiy on 11.05.2023.
//

import Foundation
import UIKit

extension UIColor {
    static let buttonColor = UIColor { traitCollection -> UIColor in
        traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
    }
}
