//
//  Friend.swift
//  WEvent
//
//  Created by Toby Gamble on 3/7/22.
//

import Foundation
import UIKit

class Friend {
    // Stored properties.
    var id: String
    var profilePic: UIImage?
    var firstName: String
    var lastName: String
    var email: String
    var status: String
    
    // Computed property.
    var fullName: String {
        get {
            return "\(firstName) \(lastName)"
        }
    }
    
    // Initializer.
    init(id: String, profilePic: UIImage? = nil, firstName: String, lastName: String, email: String, status: String) {
        self.id = id
        self.profilePic = profilePic
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.status = status
    }
}
