//
//  OverpasProtocol.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 18.09.2023.
//

import Foundation

protocol OverpasProtocol: NSObject {
    func downloadProgress(_ loaded: Int64)
    func downloadCompleted(with result: URL)
}
