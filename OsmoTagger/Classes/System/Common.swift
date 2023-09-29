//
//  Common.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 19.09.2023.
//

import Foundation
import UIKit

typealias EmptyBlock = () -> Void
typealias TagBlock = ([String: String]) -> Void

let isPad = UIDevice.current.userInterfaceIdiom == .pad

public func Log(_ log: String) {
    AppSettings.settings.logs.append(log)
}
