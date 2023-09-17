//
//  OverpasClient.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 17.09.2023.
//

import Foundation


class OverpasClient {
    let session = URLSession.shared
    
    func getData(urlStr: String) async throws {
        guard let url = URL(string: urlStr) else {
            throw "Error generate URL"
        }
        let (data, _) = try await session.data(from: url)
        
        let parser = XMLParser(data: data)
        let parserDelegate = OSMXmlParser()
        parser.delegate = parserDelegate
        parser.parse()
        AppSettings.settings.inputObjects = parserDelegate.objects
        
    }
    
}
