//
//  ProfileTableViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/25/22.
//

import UIKit
import Firebase
import FirebaseAuth

class LandingViewController: UIViewController {

    @IBOutlet weak var activityInd: UIActivityIndicatorView!
    @IBOutlet weak var statusLbl: UILabel!
    
    var signIn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Check if user is already logged in and retrieve user information from Firebase if so.
        if Auth.auth().currentUser != nil {
//            print("Current User: " + Auth.auth().currentUser!.uid)
            getCurrentUserData()
        } else {
            goToSignIn()
        }
    }

    func getCurrentUserData() {
        activityInd.startAnimating()
        statusLbl.text = "Signing you in..."
        
        let db = Firestore.firestore()
        let docId = Auth.auth().currentUser?.uid
        let docRef = db.collection("users").document(docId!)
        
        statusLbl.text = "Retrieving user data..."
        docRef.getDocument() { (document, err) in
            if let document = document, document.exists {
//                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
//                print("Document data: \(dataDescription)")
                
                guard let userData = document.data(),
                      let fName = userData["firstName"] as? String,
                      let lName = userData["lastName"] as? String,
                      let email = userData["email"] as? String,
                      let addDate = userData["addDate"] as? Timestamp,
                      let recents = userData["recentSearches"] as? [String]
                else {
                    print("There was an error retreiving user data")
                    return
                }
                
                self.statusLbl.text = "Loading your events..."
                
                // Get user events from Firebase.
                var events = [Event]()
                
                docRef.collection("events").getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            let id  = document.documentID
                            let eventData = document.data()
                            guard let title = eventData["title"] as? String,
                                  let date = eventData["date"] as? String,
                                  let address = eventData["address"] as? String,
                                  let link = eventData["link"] as? String,
                                  let description = eventData["description"] as? String,
                                  let tickets = eventData["tickets"] as? [[String: Any]],
                                  let thumb = eventData["thumbnail"] as? String,
                                  let status = eventData["status"] as? String,
                                  let favorite = eventData["isFavorite"] as? Bool,
                                  let created = eventData["isCreated"] as? Bool
                            else {
                                print("There was an error retreiving event data")
                                return
                            }
                            
                            // Create Event object and add to events array.
                            events.append(Event(id: id, title: title, date: date, address: address, link: link, description: description, tickets: tickets, thumbnail: thumb, status: status, isFavorite: favorite, isCreated: created))
                        }
                    }
                    
                    self.statusLbl.text = "Loading your friends..."
                    
                    // Get user friends from Firebase.
                    var friends = [[String: Any]]()
                    
                    docRef.collection("friends").getDocuments() { (querySnapshot, err) in
                        if let err = err {
                            print("Error getting documents: \(err)")
                        } else {
                            for document in querySnapshot!.documents {
                                print("\(document.documentID) => \(document.data())")
                            }
                        }
                        
                        self.statusLbl.text = "Finishing up..."
                        
                        // Get user profile picture.
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
                        
                        // Set current user.
                        CurrentUser.currentUser = User(profilePic: img, firstName: fName, lastName: lName, email: email, addDate: addDate.dateValue(), friends: friends, userEvents: events, recentSearches: recents)
                        
                        self.goToSignIn()
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func goToSignIn() {
        statusLbl.isHidden = true
        activityInd.isHidden = true
        activityInd.stopAnimating()
        
        // Show SignInViewController
        signIn = true
        performSegue(withIdentifier: "goToSignIn", sender: self)
    }

    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return signIn
    }
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
