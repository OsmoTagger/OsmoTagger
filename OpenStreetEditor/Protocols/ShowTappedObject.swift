//
//  ShowTappedObject.swift
//  OSM editor
//
//  Created by Arkadiy on 30.03.2023.
//

import Foundation
import GLMap

//  The protocol is used to highlight tapped objects from the screen of saved objects, or the screen that is displayed if the tap was performed on several objects at once: SelectObjectVC.
protocol ShowTappedObject: NSObject {
    func showTapObject(object: GLMapVectorObject)
    func updateSourceData()
    func removeEditDrawble()
}
