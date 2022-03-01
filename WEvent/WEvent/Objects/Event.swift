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
    var thumbnail: String
    var status: String?
    var isFavorite: Bool?
    var isCreated: Bool?
    
    // Computed properties.
    var image: UIImage {
        get {
            var img = UIImage()
            // Check if article contains image data.
            // Articles that do not have image data will contain non-URL strings ("self").
            // Check that imageString (image data) contains a URL string by checking for "http" in the string.
            if thumbnail.contains("http"),
               let url = URL(string: thumbnail),
               // Create URLComponent object to convert URL from "http" (not secure) to "https" (secure).
               var urlComp = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                
                urlComp.scheme = "https"

                if let secureURL = urlComp.url {
                    // Retrieve image from secureURL created above.
                    do {
                        img = UIImage(data: try Data.init(contentsOf: secureURL))!
                    } catch {
                        print("Error: \(error.localizedDescription)")

                        img = UIImage(named: "corner_pattern")!
                    }
                }
            } else {
                img = UIImage(named: "corner_pattern")!
            }

            return img
        }
    }
    
    // Initializer.
    init(id: String, title: String, date: String, address: String, link:String, description: String, tickets: [[String: Any]], thumbnail: String, status: String? = "", isFavorite: Bool? = false, isCreated: Bool? = false) {
        self.id = id
        self.title = title
        self.date = date
        self.address = address
        self.link = link
        self.description = description
        self.tickets = tickets
        self.thumbnail = thumbnail
        self.status = status
        self.isFavorite = isFavorite
        self.isCreated = isCreated
    }
    
//    enum CodingKeys: String, CodingKey {
//        case title
//        case date
//        case address
//        case link
//        case description
//        case thumbnail
//    }
}
