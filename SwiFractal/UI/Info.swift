//
//  Info.swift
//  SwiFractal
//
//  Created by Dirk Braner on 29.09.26.
//

import Foundation


///
/// Information displayed in StatusView
///
struct Info {

    var currentAction: String = "Idle"
    var statusMessage: String = "Ready."
    var mousePosition: String = ""
    var selectedArea: String = ""
    
    mutating func setState(currentAction: String, statusMessage: String = "") {
        self.currentAction = currentAction
        self.statusMessage = statusMessage
    }

}

