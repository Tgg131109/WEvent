//
//  Event.swift
//  WEvent
//
//  Created by Toby Gamble on 2/25/22.
//

import Foundation
import UIKit
import CoreLocation

class Event {
    // Stored properties.
    var id: String
    var title: String
    var date: String
    var address: String
    var link: String
    var description: String
    var tickets: [[String: Any]]
    var imageUrl: String
    var image: UIImage
    var groupId: String
    var attendeeIds: [String]
    var status: String
    var isFavorite: Bool
    var isCreated: Bool
    
    // Initializer.
    init(id: String, title: String, date: String, address: String, link:String, description: String, tickets: [[String: Any]], imageUrl: String, image: UIImage, groupId: String, attendeeIds: [String], status: String? = "", isFavorite: Bool? = false, isCreated: Bool? = false) {
        self.id = id
        self.title = title
        self.date = date
        self.address = address
        self.link = link
        self.description = description
        self.tickets = tickets
        self.imageUrl = imageUrl
        self.image = image
        self.groupId = groupId
        self.attendeeIds = attendeeIds
        self.status = status!
        self.isFavorite = isFavorite!
        self.isCreated = isCreated!
    }
}
