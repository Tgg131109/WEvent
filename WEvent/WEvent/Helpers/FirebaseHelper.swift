//
//  FirebaseHelper.swift
//  WEvent
//
//  Created by Toby Gamble on 3/1/22.
//

import Foundation
import Firebase
import UIKit

protocol UserDataDelegate {
    func getCriticalData() async throws
    func getBackgroundData() async throws
}

protocol FavoritesDelegate {
    func setFavorite(event: Event, isFav: Bool)
}

class FirebaseHelper: UserDataDelegate, FavoritesDelegate {
    
    let db = Firestore.firestore()
    let docId = Auth.auth().currentUser?.uid
    var docRef: DocumentReference?
    
    var allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
    
    func getCriticalData() async throws {
            do {
                try await setCurrentUser()
            } catch {
                print("There was an error setting current user data.")
            }
            
            do {
                try await getUserEvents()
            } catch {
                print("There was an error getting user events.")
            }
    }
    
    func getBackgroundData() async throws {
            do {
                try await getUserFriends()
            } catch {
                print("There was an error getting user friends.")
            }
        
        getUserProfilePic()
    }
    
    func setCurrentUser() async throws {
        docRef = db.collection("users").document(docId!)
        var document: DocumentSnapshot
        
        do {
            try await document = docRef!.getDocument()
            
            guard let userData = document.data(),
                  let fName = userData["firstName"] as? String,
                  let lName = userData["lastName"] as? String,
                  let email = userData["email"] as? String,
                  let addDate = userData["addDate"] as? Timestamp,
                  let recents = userData["recentSearches"] as? [String]
            else {
                print("There was an error setting current user data")
                return
            }
            
            let img = UIImage(named: "corner_pattern")!
            
            if CurrentUser.currentUser == nil {
                // Set current user.
                CurrentUser.currentUser = User(profilePic: img, firstName: fName, lastName: lName, email: email, addDate: addDate.dateValue(), friends: [[String: Any]](), userEvents: [Event](), recentSearches: recents)
            } else {
                // Update current user info.
                CurrentUser.currentUser?.firstName = fName
                CurrentUser.currentUser?.lastName = lName
                CurrentUser.currentUser?.email = email
                CurrentUser.currentUser?.addDate = addDate.dateValue()
                CurrentUser.currentUser?.recentSearches = recents
            }
        } catch {
            print("There was an error retreiving user data")
        }
    }
    
    func getUserEvents() async throws {
        var events = [Event]()
        var querySnapshot: QuerySnapshot
        
        do {
            try await querySnapshot = docRef!.collection("events").getDocuments()
            
            for document in querySnapshot.documents {
                let id  = document.documentID
                let eventData = document.data()
                guard let title = eventData["title"] as? String,
                      let date = eventData["date"] as? String,
                      let address = eventData["address"] as? String,
                      let link = eventData["link"] as? String,
                      let description = eventData["description"] as? String,
                      let tickets = eventData["tickets"] as? [[String: Any]],
                      let imageUrl = eventData["thumbnail"] as? String,
                      let status = eventData["status"] as? String,
                      let favorite = eventData["isFavorite"] as? Bool,
                      let created = eventData["isCreated"] as? Bool
                else {
                    print("There was an error setting event data")
                    return
                }
                
                let getImageDelegate: GetImageDelegate! = GetImageHelper()
                let eventImage = getImageDelegate.getImageFromUrl(imageUrl: imageUrl)
                                                
                // Create Event object and add to events array.
                events.append(Event(id: id, title: title, date: date, address: address, link: link, description: description, tickets: tickets, imageUrl: imageUrl, image: eventImage, status: status, isFavorite: favorite, isCreated: created))
            }
            
            let img = UIImage(named: "logo_stamp")!
            
            if CurrentUser.currentUser == nil {
                // Set current user.
                CurrentUser.currentUser = User(profilePic: img, firstName: "", lastName: "", email: "", addDate: Date(), friends: [[String: Any]](), userEvents: events, recentSearches: [String]())
            } else {
                // Update current user info.
                CurrentUser.currentUser?.userEvents = events
            }
        } catch {
            print("There was an error retreiving user events")
        }
    }
    
    func getUserFriends() async throws {
        var friends = [[String: Any]]()
        var querySnapshot: QuerySnapshot
        
        do {
            try await querySnapshot = docRef!.collection("friends").getDocuments()
            
            for document in querySnapshot.documents {
                print("\(document.documentID) => \(document.data())")
                
                // Create User object and add to events array.
            }
            
            let img = UIImage(named: "corner_pattern")!
            
            if CurrentUser.currentUser == nil {
                // Set current user.
                CurrentUser.currentUser = User(profilePic: img, firstName: "", lastName: "", email: "", addDate: Date(), friends: friends, userEvents: [Event](), recentSearches: [String]())
            } else {
                // Update current user info.
                CurrentUser.currentUser?.friends = friends
            }
        } catch {
            print("There was an error retreiving user friends")
        }
    }

    func getUserProfilePic() {
        let profilePic = Auth.auth().currentUser?.photoURL

        var img = UIImage()

        if profilePic != nil {
            do {
                img = UIImage(data: try Data.init(contentsOf: profilePic!))!
            } catch {
                print("Error: \(error.localizedDescription)")

                img = UIImage(named: "corner_pattern")!
            }
        } else {
            img = UIImage(named: "corner_pattern")!
        }

        if CurrentUser.currentUser == nil {
            // Set current user.
            CurrentUser.currentUser = User(profilePic: img, firstName: "", lastName: "", email: "", addDate: Date(), friends: [[String: Any]](), userEvents: [Event](), recentSearches: [String]())
        } else {
            // Update current user info.
            CurrentUser.currentUser?.profilePic = img
        }
    }
    
    func setFavorite(event: Event, isFav: Bool) {
        docRef = db.collection("users").document(docId!)
        
        if docRef != nil {
            // Check if event is in allUserEvents array.
            if let index = allUserEvents.firstIndex(where: { $0.title == event.title }) {
                if event.status != "" {
                    // Find document in Firebase and update favorite field.
                    docRef!.collection("events").document(event.id).updateData(["isFavorite": isFav]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            // Update event isFavorite property and update current user's events to match.
                            self.allUserEvents[index].isFavorite = isFav
                            CurrentUser.currentUser?.userEvents = self.allUserEvents
                            
                            print("Document successfully updated")
                        }
                    }
                } else {
                    // Remove event from user's events in Firebase.
                    docRef!.collection("events").document(event.id).delete() { err in
                        if let err = err {
                            print("Error removing document: \(err)")
                        } else {
                            // Remove event from allUserEvents array and update current user's events to match.
                            self.allUserEvents.removeAll(where: { $0.id == event.id })
                            CurrentUser.currentUser?.userEvents = self.allUserEvents
                            
                            print("Document successfully removed!")
                        }
                    }
                }
            } else {
                // Add event to user's events in Firebase.
                let data: [String: Any] = ["thumbnail": event.imageUrl, "title": event.title, "date": event.date, "tickets": event.tickets, "address": event.address, "link": event.link, "description": event.description, "status": "", "isCreated": false, "isFavorite": true]
                
                var ref: DocumentReference?
                
                ref = docRef!.collection("events").addDocument(data: data) { (error) in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else {
                        if let id = ref?.documentID {
                            event.id = id
                            event.isFavorite = true
                            
                            self.allUserEvents.append(event)
                            CurrentUser.currentUser?.userEvents = self.allUserEvents
                            
                            print("Document added with ID: \(id)")
                        }
                    }
                }
            }
        }
    }
}
