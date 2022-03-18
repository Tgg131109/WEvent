//
//  AddFriendsViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 3/7/22.
//

import UIKit
import Firebase
import Kingfisher

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
        
        navigationController?.popViewController(animated: true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchStr = searchBar.text, !searchStr.isEmpty
        else {
            print("Search bar is empty")
            return
        }
        
        resultCountLbl.text = "Searching..."
        // Run query
        findUsers(searchStr: searchStr)
    }
    
    private func findUsers(searchStr: String) {
        searchResults.removeAll()
        
        let collRef = db.collection("users")
        
        var foundIds = [String]()
        var methodCount = 0
        // Search by first name.
        collRef.whereField("firstName", isGreaterThanOrEqualTo: searchStr).whereField("firstName", isLessThanOrEqualTo: "\(searchStr)~").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    // Check if user has already been found.
                    let id = document.documentID
                    if !foundIds.contains(id) && !self.friendIds.contains(id) && id != Auth.auth().currentUser?.uid {
                        foundIds.append(document.documentID)
                        
                        self.getUserData(document: document)
                    }
                }
            }
            
            methodCount += 1
            self.doneSearch(count: methodCount)
        }
        
        // Search by last name.
        collRef.whereField("lastName", isGreaterThanOrEqualTo: searchStr).whereField("lastName", isLessThanOrEqualTo: "\(searchStr)~").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    // Check if user has already been found.
                    let id = document.documentID
                    if !foundIds.contains(id) && !self.friendIds.contains(id) && id != Auth.auth().currentUser?.uid {
                        foundIds.append(document.documentID)
                        
                        self.getUserData(document: document)
                    }
                }
            }
            
            methodCount += 1
            self.doneSearch(count: methodCount)
        }
        
        // Search by email.
        collRef.whereField("email", isGreaterThanOrEqualTo: searchStr).whereField("email", isLessThanOrEqualTo: "\(searchStr)~").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    // Check if user has already been found.
                    let id = document.documentID
                    if !foundIds.contains(id) && !self.friendIds.contains(id) && id != Auth.auth().currentUser?.uid {
                        foundIds.append(document.documentID)
                        
                        self.getUserData(document: document)
                    }
                }
            }
            
            methodCount += 1
            self.doneSearch(count: methodCount)
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
        searchResults.append(Friend(id: document.documentID, profilePic: UIImage(named: "logo_placeholder")!, firstName: fName, lastName: lName, email: email, status: ""))
        getUserImage(docId: document.documentID)
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
                    self.searchResults.first(where: { $0.id == docId })?.picUrl = url.absoluteString
                    self.tableView.reloadData()
                    self.resultCountLbl.text = self.searchResults.count > 1 ? "\(self.searchResults.count) users found" : "1 user found"
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
    
    private func doneSearch(count: Int) {
        if count == 3 {
            if searchResults.isEmpty {
                resultCountLbl.text = "No users found"
                tableView.reloadData()
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
        
        cell.userImageIV.kf.indicatorType = .activity
        cell.userImageIV.kf.setImage(with: URL(string: user.picUrl ?? ""), placeholder: UIImage(named: "logo_placeholder"), options: [.transition(.fade(1))], completionHandler: { result in
            switch result {
            case .success(let value):
                user.profilePic = value.image
                self.searchResults[indexPath.row].profilePic = value.image
                break
                
            case .failure(let error):
                if !error.isTaskCancelled && !error.isNotCurrentTask {
                    print("Error getting image: \(error)")
                }
                break
            }
        })
        
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
            
            self.requestBtn.setTitle(self.requestedFriends.count > 1 ? "Send Requests" : "Send Request", for: .normal)
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
