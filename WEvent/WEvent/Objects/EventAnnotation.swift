//
//  EventAnnotation.swift
//  WEvent
//
//  Created by Toby Gamble on 2/26/22.
//

import Foundation
import MapKit

class EventAnnotation: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D
    
    init(title: String?, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
        
        super.init()
    }
}
