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

protocol EventDataDelegate {
    func addUserEvent(uId: String, eventId: String, groupId: String, isCreated: Bool, completion: @escaping (Bool) -> ())
    func addFirebaseGroup(eventId: String, completion: @escaping (String) -> ())
    func setFavorite(event: Event, isFav: Bool)
    func deleteFirebaseEvent(event: Event, completion: @escaping (Bool) -> ())
}

class FirebaseHelper: UserDataDelegate, EventDataDelegate {
    
    let db = Firestore.firestore()
    let userId = Auth.auth().currentUser?.uid
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
        
//        do {
//            try await getInvitedEvents()
//        } catch {
//            print("There was an error getting user invites.")
//        }
        
        getUserProfilePic()
    }
    
    func setCurrentUser() async throws {
        docRef = db.collection("users").document(userId!)
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
            
            let img = UIImage(named: "logo_placeholder")!
            
            if CurrentUser.currentUser == nil {
                // Set current user.
                CurrentUser.currentUser = User(profilePic: img, firstName: fName, lastName: lName, email: email, addDate: addDate.dateValue(), friends: [Friend](), userEvents: [Event](), recentSearches: recents)
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
            
            // Get each users event references.
            for document in querySnapshot.documents {
                let id  = document.documentID
                let eventData = document.data()
                guard let groupId = eventData["groupId"] as? String,
                      let status = eventData["status"] as? String,
                      let favorite = eventData["isFavorite"] as? Bool,
                      let created = eventData["isCreated"] as? Bool
                else {
                    print("There was an error setting event data")
                    continue
                }
                
                var doc: DocumentSnapshot

                // Get event from Firebase "events" collection.
                try await doc = db.collection("events").document(id).getDocument()
                
                guard let docData = doc.data(),
                      let title = docData["title"] as? String,
                      let date = docData["date"] as? String,
                      let address = docData["address"] as? String,
                      let link = docData["link"] as? String,
                      let description = docData["description"] as? String,
                      let tickets = docData["tickets"] as? [[String: Any]],
                      let imageUrl = docData["thumbnail"] as? String
                else {
                    print("Firebase event does not exist.")
                    continue
                }
                
                var organizerId = ""
                var attendeeIds = [String]()
                var pendingIds = [String]()
                
                if !groupId.isEmpty {
                // Get group from Firebase "groups" collection.
                    try await doc = db.collection("groups").document(groupId).getDocument()
                    
                    guard let groupData = doc.data(),
                          let orgId = groupData["organizerId"] as? String,
                          let memberIds = groupData["memberIds"] as? [String],
                          let invitedIds = groupData["pendingIds"] as? [String]
                    else {
                        print("There was an error setting event group data")
                        continue
                    }
                    
                    organizerId = orgId
                    attendeeIds = memberIds
                    pendingIds = invitedIds
                }
                
                // Create Event object and add to events array.
                events.append(Event(id: id, title: title, date: date, address: address, link: link, description: description, tickets: tickets, imageUrl: imageUrl, image: UIImage(named: "logo_placeholder")!, groupId: groupId, organizerId: organizerId, attendeeIds: attendeeIds, pendingIds: pendingIds, status: status, isFavorite: favorite, isCreated: created))
            }
            
            let img = UIImage(named: "logo_placeholder")!
            
            if CurrentUser.currentUser == nil {
                // Set current user.
                CurrentUser.currentUser = User(profilePic: img, firstName: "", lastName: "", email: "", addDate: Date(), friends: [Friend](), userEvents: events, recentSearches: [String]())
            } else {
                // Update current user info.
                CurrentUser.currentUser?.userEvents = events
            }
        } catch {
            print("There was an error retreiving user events")
        }
    }
    
    func getUserFriends() async throws {
        var friends = [Friend]()
        var querySnapshot: QuerySnapshot
        
        do {
            try await querySnapshot = docRef!.collection("friends").getDocuments()
            
            for document in querySnapshot.documents {
                let userData = document.data()
                
                guard let fName = userData["firstName"] as? String,
                      let lName = userData["lastName"] as? String,
                      let email = userData["email"] as? String,
                      let status = userData["status"] as? String
                else {
                    print("There was an error setting current user data")
                    return
                }
                
                // Create User object and add to events array.
                friends.append(Friend(id: document.documentID, profilePic: UIImage(named: "logo_placeholder")!, firstName: fName, lastName: lName, email: email, status: status))
            }
            
            let img = UIImage(named: "logo_placeholder")!
            
            if CurrentUser.currentUser == nil {
                // Set current user.
                CurrentUser.currentUser = User(profilePic: img, firstName: "", lastName: "", email: "", addDate: Date(), friends: friends, userEvents: [Event](), recentSearches: [String]())
            } else {
                // Update current user info.
                CurrentUser.currentUser?.friends = friends
            }
            
            // Retrieve each friend's profile picture url.
            for friend in friends {
                getFriendProfilePic(docId: friend.id)
            }
        } catch {
            print("There was an error retreiving user friends")
        }
    }

    func getUserProfilePic() {
        let profilePic = Auth.auth().currentUser?.photoURL

        var img = UIImage(named: "logo_placeholder")!

        if profilePic != nil {
            do {
                img = UIImage(data: try Data.init(contentsOf: profilePic!))!
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }

        if CurrentUser.currentUser == nil {
            // Set current user.
            CurrentUser.currentUser = User(profilePic: img, firstName: "", lastName: "", email: "", addDate: Date(), friends: [Friend](), userEvents: [Event](), recentSearches: [String]())
        } else {
            // Update current user info.
            CurrentUser.currentUser?.profilePic = img
        }
    }
    
    func getFriendProfilePic(docId: String) {
        // Get user image.
        let storageRef = Storage.storage().reference().child("users").child(docId).child("profile.png")
        
        storageRef.downloadURL { url, error in
            if let error = error {
                // Handle any errors
                print("There was an error: \(error)")
            } else {
                if let url = url {
                    CurrentUser.currentUser?.friends?.first(where: { $0.id == docId})?.picUrl = url.absoluteString
                }
            }
        }
    }
    
    func addUserEvent(uId: String, eventId: String, groupId: String, isCreated: Bool, completion: @escaping (Bool) -> ()) {
        // Add event to user's Firebase "events" collection.
        let ref = db.collection("users").document(uId)
        let data: [String: Any] = ["groupId": groupId, "status": "attending", "isCreated": isCreated, "isFavorite": false]
        
        ref.collection("events").document(eventId).setData(data) { (error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(false)
            } else {
                print("User event document added with ID: \(eventId)")
                completion(true)
            }
        }
    }
    
    func addFirebaseGroup(eventId: String, completion: @escaping (String) -> ()) {
        // Create new group in Firbase.
        var ref: DocumentReference? = nil
        let data: [String: Any] = ["eventId": eventId, "organizerId": self.userId!, "memberIds": [self.userId!], "pendingIds": [String]()]
        
        ref = db.collection("groups").addDocument(data: data) { (error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion("error")
            } else {
                print("Group document added with ID: \(ref!.documentID)")
                
                // Find document in Firebase and update status field.
                self.db.collection("users").document(self.userId!).collection("events").document(eventId).updateData(["groupId": ref!.documentID]) { err in
                    if let err = err {
                        print("Error updating groupId: \(err)")
                    } else {
                        completion(ref!.documentID)
                        print("GroupId successfully updated in Firebase.")
                    }
                }
            }
        }
    }
    
    func setFavorite(event: Event, isFav: Bool) {
        docRef = db.collection("users").document(userId!)

        // Check if event is in already is user's userEvents array.
        if let index = CurrentUser.currentUser?.userEvents?.firstIndex(where: { $0.id == event.id }) {
            if event.status != "" {
                // Immediately update event's isFavorite property.
                CurrentUser.currentUser?.userEvents?[index].isFavorite = isFav
                
                // Find document in Firebase and update favorite field.
                docRef!.collection("events").document(event.id).updateData(["isFavorite": isFav]) { err in
                    if let err = err {
                        print("Error updating favorite: \(err)")
                    } else {
                        print("Favorite successfully updated")
                    }
                }
            } else {
                // This only occurs when a user is unfavoriting an event (status = "").
                // Remove event from user's events in Firebase.
                deleteFirebaseEvent(event: event) { result in
                    if result == false {
                        print("Error removing user favorite")
                    } else {
                        print("Favorite successfully removed!")
                    }
                }
            }
        } else {
            // This only occurs if user is favoriting an event that they have not set as attending or have been invited to.
            // Immediately set favorite value and add to user's userEvents array.
            event.isFavorite = true
            CurrentUser.currentUser?.userEvents?.append(event)
            
            // Check if event already exists in Firebase "events" collection.
            let collRef = db.collection("events")
            
            collRef.whereField("title", isEqualTo: event.title).whereField("link", isEqualTo: event.link).getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    // If event already exists, just add a reference to it to the user's "events" collection.
                    if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                        let eId = querySnapshot.documents[0].documentID
                        
                        event.id = eId
                        self.addUserFavorite(event: event)
                    } else {
                        // Add event to Firebase "events" collection.
                        let data: [String: Any] = ["thumbnail": event.imageUrl, "title": event.title, "date": event.date, "tickets": event.tickets, "address": event.address, "link": event.link, "description": event.description]
                        
                        var ref: DocumentReference?
                        
                        ref = self.db.collection("events").addDocument(data: data) { (error) in
                            if let error = error {
                                print("Error: \(error.localizedDescription)")
                            } else {
                                if let id = ref?.documentID {
                                    event.id = id
                                    self.addUserFavorite(event: event)
                                    
                                    print("Firebase event added for favorite with ID: \(id)")
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    func addUserFavorite(event: Event) {
        // Add event to user's Firebase "events" collection.
        let ref = db.collection("users").document(self.userId!)
        let data: [String: Any] = ["groupId": event.groupId, "status": event.status, "isCreated": false, "isFavorite": true]
        
        ref.collection("events").document(event.id).setData(data) { (error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                print("User favorite event added with ID: \(event.id)")
            }
        }
    }
    
    func deleteFirebaseEvent(event: Event, completion: @escaping (Bool) -> ()) {
        // Immediately remove event from user's userEvents array.
        CurrentUser.currentUser?.userEvents?.removeAll(where: { $0.id == event.id })
                
        docRef = db.collection("users").document(userId!)
        // Remove event from user's events in Firebase
        if docRef != nil {
            docRef!.collection("events").document(event.id).delete() { err in
                if let err = err {
                    print("Error removing event: \(err)")
                    completion(false)
                } else {
                    // Remove group from Firebase if the current user is the only one in the group.
                    if event.attendeeIds.count == 1 && event.attendeeIds[0] == self.userId {
                        self.db.collection("groups").document(event.groupId).delete() { err in
                            if let err = err {
                                print("Error removing group: \(err)")
                            } else {
                                print("Group successfully removed.")
                            }
                        }
                    } else if event.attendeeIds.count > 1 {
                        self.db.collection("groups").document(event.groupId).updateData(["memberIds": FieldValue.arrayRemove([self.userId!])]) { err in
                            if let err = err {
                                print("Error updating group: \(err)")
                            } else {
                                print("Group successfully updated.")
                            }
                        }
                    }
                                        
                    completion(true)
                    
                    print("Event successfully removed!")
                }
            }
            
            if event.isCreated {
                // Delete event image from Firebase Storage.
                let storageRef = Storage.storage().reference().child("users").child(userId!).child("events").child(event.id).child("thumbnail.png")
                
                storageRef.delete { err in
                    if let err = err {
                        print("Error deleting image: \(err)")
                    } else {
                        print("Image successfully deleted")
                    }
                }
                
                // Delete event from Firebase "events" collection.
                db.collection("events").document(event.id).delete() { err in
                    if let err = err {
                        print("Error removing event: \(err)")
                    } else {
                        print("Event successfully removed from Firebase.")
                    }
                }
            }
        }
    }
}
