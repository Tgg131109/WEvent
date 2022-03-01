//
//  SignInViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/20/22.
//

import UIKit
import Firebase
import FirebaseAuth

class SignInViewController: UIViewController {

    @IBOutlet weak var emailField: CustomTextField!
    @IBOutlet weak var passwordField: CustomTextField!
    @IBOutlet weak var signInBtn: UIButton!
    @IBOutlet weak var forgotPasswordBtn: UIButton!
    @IBOutlet weak var facebookBtn: UIButton!
    @IBOutlet weak var googleBtn: UIButton!
    @IBOutlet weak var signUpBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.isHidden = true
        
        if CurrentUser.currentUser != nil {
            // Show HomeViewController.
            self.performSegue(withIdentifier: "goToHome", sender: self)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if Auth.auth().currentUser == nil && view.isHidden {
            view.isHidden.toggle()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if Auth.auth().currentUser == nil {
            view.isHidden = true
        }
    }
    
    @IBAction func signInBtnTapped(_ sender: UIButton) {
        // Create alert to be displayed if proper conditions are not met.
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        // Add action to alert controller.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Ensure required fields are not empty.
        guard let email = emailField.text,!email.isEmpty,
              let password = passwordField.text, !password.isEmpty
        else {
            // Set alert title and message.
            alert.title = "Missing Info"
            alert.message = "All fields must be completed to continue."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        // Use Firebase to authenticate user if signing in with email and password.
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {result, error in
            // Ensure there are no errors while signing in.
            guard error == nil
            // Action if error occurs.
            else {
                // Set alert title and message.
                alert.title = "Sign In Failed"
                alert.message = "The email or password that you entered is incorrect. Please enter the correct email and password and try again."
                
                // Show alert.
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            print("You have been signed in.")

            self.getCurrentUserData()
        })
    }
    
    func getCurrentUserData() {
        let db = Firestore.firestore()
        let docId = Auth.auth().currentUser?.uid
        let docRef = db.collection("users").document(docId!)
        
        docRef.getDocument() { (document, err) in
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
                
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
                
                // Get user events from Firebase.
                var events = [Event]()
                
                docRef.collection("events").getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            print("\(document.documentID) => \(document.data())")
                            
                            let id  = document.documentID
                            let eventData = document.data()
                            guard let title = eventData["title"] as? String,
                                  let date = eventData["date"] as? String,
                                  let address = eventData["address"] as? String,
                                  let link = eventData["link"] as? String,
                                  let description = eventData["description"] as? String,
                                  let tickets = eventData["tickets"] as? [[String: Any]],
                                  let thumb = eventData["thumbnail"] as? String
                            else {
                                print("There was an error retreiving event data")
                                continue
                            }
                            
                            // Create Event object and add to events array.
                            events.append(Event(id: id, title: title, date: date, address: address, link: link, description: description, tickets: tickets, thumbnail: thumb))
                        }
                    }
                    
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
                        
                        // Show HomeViewController.
                        self.performSegue(withIdentifier: "goToHome", sender: self)
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}

