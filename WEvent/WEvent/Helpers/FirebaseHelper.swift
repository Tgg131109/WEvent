//
//  FirebaseHelper.swift
//  WEvent
//
//  Created by Toby Gamble on 3/1/22.
//

import Foundation
import Firebase
import UIKit

protocol FavoritesDelegate {
    func setFavorite(event: Event, isFav: Bool)
}

class FirebaseHelper: FavoritesDelegate {
    
    let db = Firestore.firestore()
    let docId = Auth.auth().currentUser?.uid
    var docRef: DocumentReference?
    
    var allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
        
    func setFavorite(event: Event, isFav: Bool) {
        docRef = db.collection("users").document(docId!)
        
        if docRef != nil {
            // Check if event is in allUserEvents array.
            if let index = allUserEvents.firstIndex(where: { $0.title == event.title }) {
                //        if allUserEvents.contains(where: { $0.title == event.title }) {
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
                let data: [String: Any] = ["thumbnail": event.thumbnail, "title": event.title, "date": event.date, "tickets": event.tickets, "address": event.address, "link": event.link, "description": event.description, "status": "", "isCreated": false, "isFavorite": true]
                
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
