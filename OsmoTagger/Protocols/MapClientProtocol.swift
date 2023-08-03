//
//  MapClientProtocol.swift
//  OpenStreetEditor
//
//  Created by Arkadiy on 29.05.2023.
//

import Foundation
import GLMap

//  The protocol is used to send data from MapClient to MapViewController.
protocol MapClientProtocol: NSObject {
    // Add and remove drawble layers
    func addDrawble(layer: GLMapDrawable)
    func removeDrawble(layer: GLMapDrawable)
    // Start and end animations of load in MapViewController
    func startDownload()
    func endDownload()
}
