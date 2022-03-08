//
//  Location.swift
//  WEvent
//
//  Created by Toby Gamble on 3/6/22.
//

import Foundation

class Location {
    // Stored Properties.
    let city: String
    let coordinates: [Double]
    let state: String
    let id: String
    
    // Computed Property.
    var fullName: String {
        get {
            return "\(city), \(state)"
        }
    }
    
    var searchStr: String {
        get {
            let formattedCity = city.replacingOccurrences(of: " ", with: "+")
            return "\(formattedCity)+\(state)"
        }
    }
    
    // Initializer.
    init(city: String, coordinates: [Double], state: String, id: String) {
        self.city = city
        self.coordinates = coordinates
        self.state = state
        self.id = id
    }
}
