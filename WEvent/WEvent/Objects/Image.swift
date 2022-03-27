//
//  Image.swift
//  WEvent
//
//  Created by Toby Gamble on 3/21/22.
//

import Foundation
import UIKit
import Firebase

class Image {
    // Stored properties.
    var image: UIImage?
    var imgUrl: String
    var userId: String
    
    // Computed properties.
    var userName: String {
        get {
            if userId == Auth.auth().currentUser?.uid {
                return "You"
            } else {
                return CurrentUser.currentUser?.friends?.first(where: { $0.id == userId })?.firstName ?? "A friend"
            }
        }
    }
    
    var userProfilePic: UIImage {
        get {
            if userId == Auth.auth().currentUser?.uid {
                return CurrentUser.currentUser?.profilePic ?? UIImage(named: "logo_placeholder")!
            } else {
                return CurrentUser.currentUser?.friends?.first(where: { $0.id == userId })?.profilePic ?? UIImage(named: "logo_placeholder")!
            }
        }
    }
    
    // Initializer.
    init(image: UIImage? = nil, imgUrl: String, userId: String) {
        self.image = image
        self.imgUrl = imgUrl
        self.userId = userId
    }
}
