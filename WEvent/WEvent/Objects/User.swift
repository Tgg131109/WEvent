//
//  User.swift
//  WEvent
//
//  Created by Toby Gamble on 2/22/22.
//

import Foundation
import UIKit

class User {
    // Stored properties.
    var profilePic: UIImage?
//    var profilePic: URL?
    var firstName: String
    var lastName: String
    var email: String
    var addDate: Date
//    var isInvited: Bool
    var friends: [[String: Any]]?
    var userEvents: [Event]?
    var recentSearches: [String]?
    
    // Computed property.
    var fullName: String {
        get {
            return "\(firstName) \(lastName)"
        }
    }
    
    // Initializer.
    init(profilePic: UIImage? = nil, firstName: String, lastName: String, email: String, addDate: Date, friends: [[String: Any]]? = nil, userEvents: [Event]? = nil, recentSearches: [String]? = nil) {
        self.profilePic = profilePic
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.addDate = addDate
//        self.isInvited = isInvited
        self.friends = friends
        self.userEvents = userEvents
        self.recentSearches = recentSearches
    }
    
//    enum CodingKeys: String, CodingKey {
//        case firstName
//        case lastName
//        case email
//        case addDate
//        case isInvited
//        case userEvents
//        case recentSearches
//    }
}
