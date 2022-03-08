//
//  AddFriendsViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 3/7/22.
//

import UIKit
import Firebase

class AddFriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {

    @IBOutlet weak var resultCountLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var requestBtn: UIButton!
    
    let db = Firestore.firestore()
    
    var userFriends = [Friend]()
    var friendIds = [String]()
    var searchResults = [Friend]()
    var requestedFriends = [Friend]()
    
    private var searchController: UISearchController {
        let sc = UISearchController(searchResultsController: nil)
        
        sc.searchResultsUpdater = self
        sc.delegate = self
        sc.searchBar.delegate = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Find Friends"
        sc.definesPresentationContext = true
        
        return sc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        userFriends = CurrentUser.currentUser?.friends ?? [Friend]()
        
        for friend in userFriends {
            friendIds.append(friend.id)
        }
    }
    
    @IBAction func requestBtnTapped(_ sender: UIButton) {
        for friend in requestedFriends {
            friend.status = "pending"
        }
        
        userFriends.append(contentsOf: requestedFriends)
        CurrentUser.currentUser?.friends = userFriends
        
        saveFriendsToFirebase()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchStr = searchBar.text, !searchStr.isEmpty
        else {
            print("Search bar is empty")
            return
        }
        
        // Run query
        findUsers(searchStr: searchStr)
    }
    
    private func findUsers(searchStr: String) {
        searchResults.removeAll()
        
        let collRef = db.collection("users")
        
        var foundIds = [String]()
        
        // Search by first name.
        collRef.whereField("firstName", isGreaterThanOrEqualTo: searchStr).whereField("firstName", isLessThanOrEqualTo: "\(searchStr)~").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    // Check if user has already been found.
                    if !foundIds.contains(document.documentID) {
                        foundIds.append(document.documentID)
                        
                        self.getUserData(document: document)
                    }
                }
            }
        }
        
        // Search by last name.
        collRef.whereField("lastName", isGreaterThanOrEqualTo: searchStr).whereField("lastName", isLessThanOrEqualTo: "\(searchStr)~").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    // Check if user has already been found.
                    if !foundIds.contains(document.documentID) {
                        foundIds.append(document.documentID)
                        
                        self.getUserData(document: document)
                    }
                }
            }
        }
        
        // Search by email.
        collRef.whereField("email", isGreaterThanOrEqualTo: searchStr).whereField("email", isLessThanOrEqualTo: "\(searchStr)~").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    // Check if user has already been found.
                    if !foundIds.contains(document.documentID) {
                        foundIds.append(document.documentID)
                        
                        self.getUserData(document: document)
                    }
                }
            }
        }
    }
    
    private func getUserData(document: DocumentSnapshot) {
        // Get user data.
        let userData = document.data()
        
        guard let fName = userData?["firstName"] as? String,
              let lName = userData?["lastName"] as? String,
              let email = userData?["email"] as? String
        else {
            print("There was an error setting current user data")
            return
        }
        
        // Create Friend object and add to results array.
        searchResults.append(Friend(id: document.documentID, profilePic: UIImage(named: "logo_stamp")!, firstName: fName, lastName: lName, email: email, status: ""))
        getUserImage(docId: document.documentID)
        tableView.reloadData()
    }
    
    private func getUserImage(docId: String) {
        // Get user image.
        let storageRef = Storage.storage().reference().child("users").child(docId).child("profile.png")
        
        storageRef.downloadURL { url, error in
            if let error = error {
                // Handle any errors
                print("There was an error: \(error)")
            } else {
                if let url = url {
                    // Get the download URL.
                    do {
                        self.searchResults.first(where: { $0.id == docId})?.profilePic = UIImage(data: try Data.init(contentsOf: url))
                        self.tableView.reloadData()
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func saveFriendsToFirebase() {
        let userId = Auth.auth().currentUser!.uid
        
        for friend in requestedFriends {
            // Add friend to user's friend collection in Firebase.
            var docRef = db.collection("users").document(userId)
            var data: [String: Any] = ["firstName": friend.firstName, "lastName": friend.lastName, "email": friend.email, "status": friend.status]

            docRef.collection("friends").document(friend.id).setData(data) { (error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    print("Document data set successfully.")
                    let currentUser = CurrentUser.currentUser!
                    // Add current user to each requested friend's friend collection in firebase.
                    docRef = self.db.collection("users").document(friend.id)
                    data = ["firstName": currentUser.firstName, "lastName": currentUser.lastName, "email": currentUser.email, "status": "requested"]
                    
                    docRef.collection("friends").document(userId).setData(data) { (error) in
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                        } else {
                            print("Friend document data set successfully.")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell_9", for: indexPath)  as! FriendTableViewCell
        let user = searchResults[indexPath.row]
        
        cell.userImageIV.image = user.profilePic
        cell.userNameLbl.text = user.fullName
        cell.userEmailLbl.text = user.email
        
        cell.checkTapped = {(checkButton) in
            checkButton.isSelected.toggle()
            checkButton.tintColor = checkButton.isSelected ? UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1) : .systemGray
            
            if checkButton.isSelected {
                self.requestedFriends.append(user)
            } else {
                self.requestedFriends.removeAll(where: { $0.id == user.id})
            }
            
            self.requestBtn.isEnabled = !self.requestedFriends.isEmpty
        }

        return cell
    }

//    // MARK: - UITableViewDelegate
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
