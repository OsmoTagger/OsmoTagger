//
//  UIColor.swift
//  OpenStreetEditor
//
//  Created by Arkadiy on 11.05.2023.
//

import Foundation
import UIKit

extension UIColor {
    static let backColor0 = UIColor { (traitCollection: UITraitCollection) -> UIColor in
        traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray2 : UIColor.white
    }

    static let serparatorColor = UIColor { (traitCollection: UITraitCollection) -> UIColor in
        traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.systemGray3
    }
}
