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
    var organizerId: String
    var attendeeIds: [String]
    var pendingIds: [String]
    var status: String
    var isFavorite: Bool
    var isCreated: Bool
    
    // Computed property.
    var dateStamp: Double {
        get {
            return getDateStr().timeIntervalSince1970
        }
    }
    
    var isPast: Bool {
        get {
            return Date().timeIntervalSince1970 > getDateStr().addingTimeInterval(86400).timeIntervalSince1970
        }
    }
    
    func getDateStr() -> Date {
        let dateFormatter = DateFormatter()
        // Get 3 letter month and day from saved date.
        let dateArray = date.split(separator: "|")
        var completeDate = ""
        
        if isCreated || dateArray[0].count > 8{
            dateFormatter.dateFormat = "MMM dd yyyy hh:mm a"
            completeDate = date.replacingOccurrences(of: " |", with: "")
        } else {
            dateFormatter.dateFormat = "MMM dd yyyy"
            let year = Calendar(identifier: .gregorian).dateComponents([.year], from: Date()).year
            completeDate = "\(dateArray[0]) \(year ?? 0000)"
        }
        
        return dateFormatter.date(from: completeDate)!
    }
    
    // Initializer.
    init(id: String, title: String, date: String, address: String, link:String, description: String, tickets: [[String: Any]], imageUrl: String, image: UIImage, groupId: String, organizerId: String, attendeeIds: [String], pendingIds: [String], status: String? = "", isFavorite: Bool? = false, isCreated: Bool? = false) {
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
        self.organizerId = organizerId
        self.attendeeIds = attendeeIds
        self.pendingIds = pendingIds
        self.status = status!
        self.isFavorite = isFavorite!
        self.isCreated = isCreated!
    }
}
