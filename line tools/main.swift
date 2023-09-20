//
//  main.swift
//  Line tools
//
//  Created by Аркадий Торвальдс on 20.09.2023.
//

import Foundation


let osmFilePath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.appendingPathComponent("kaliningrad-latest.osm")


Parser().fillPresetElements()
Parser().fillChunks()

print(AppSettings.settings.categories.count)
print(AppSettings.settings.chunks.count)
let data = try! Data(contentsOf: osmFilePath)
let parser = XMLParser(data: data)
let parserDelegate = OSMXmlParser()
parser.delegate = parserDelegate
parser.parse()
print(parserDelegate.objects.count)
AppSettings.settings.inputObjects = parserDelegate.objects

print(AppSettings.settings.inputObjects)
