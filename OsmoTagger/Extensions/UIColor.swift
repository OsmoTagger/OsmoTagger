//
//  UIColor.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 24.09.2023.
//

import UIKit

extension UIColor {
    static let buttonColor = UIColor { traitCollection -> UIColor in
        traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
    }
}
