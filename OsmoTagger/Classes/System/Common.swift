//
//  Common.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 19.09.2023.
//

import Foundation

typealias EmptyBlock = () -> Void

public func Log(_ log: String) {
    AppSettings.settings.logs.append(log)
}
