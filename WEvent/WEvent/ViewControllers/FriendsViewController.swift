//
//  FriendsViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/28/22.
//

import UIKit
import Firebase

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var noFriendsLbl: UILabel!
    @IBOutlet weak var noRequestsLbl: UILabel!
    @IBOutlet weak var segCon: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var friends = [Friend]()
    var requests = [Friend]()
    var friendTypeArray = [[Friend]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let allFriends = CurrentUser.currentUser?.friends ?? [Friend]()
        
        friends = allFriends.filter({ $0.status != "requested" })
        requests = allFriends.filter({ $0.status == "requested" })
        
        friendTypeArray = [friends, requests]
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(msgLblTapped(_:)))
        
        noFriendsLbl.isHidden = !allFriends.isEmpty
        noFriendsLbl.addGestureRecognizer(tapRecognizer)
        noFriendsLbl.layer.cornerRadius = 6
        noFriendsLbl.layer.masksToBounds = true
        
        segCon.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1)], for: .selected)
    }
    
    @objc func msgLblTapped(_ sender: Any) {
        performSegue(withIdentifier: "goToAddFriends", sender: self)
    }
    
    @IBAction func cancelBtnTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func segConChanged(_ sender: UISegmentedControl) {
        if segCon.selectedSegmentIndex == 0 {
            noFriendsLbl.isHidden = !friends.isEmpty
        } else {
            noRequestsLbl.isHidden = !requests.isEmpty
        }
        
        tableView.reloadData()
    }

    private func setResponse(requester: Friend, response: String) {
        let db = Firestore.firestore()
        let userId = Auth.auth().currentUser!.uid
        var docRef = db.collection("users").document(userId)
        
        if response == "accepted" {
            // Find document in Firebase and update status field.
            docRef.collection("friends").document(requester.id).updateData(["status": response]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    // Update local friend data.
                    CurrentUser.currentUser?.friends?.first(where: { $0.id == requester.id})?.status = response
                    requester.status = response
                    
                    self.friends.append(requester)
                   
                    // Update current user status for requester's friend collection in firebase.
                    docRef = db.collection("users").document(requester.id)
                    docRef.collection("friends").document(userId).updateData(["status": response]) { (error) in
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                        } else {
                            print("Friend document data updated successfully.")
                        }
                    }
                }
            }
        } else {
            // Remove friend from Firebase.
            docRef.collection("friends").document(requester.id).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    // Update local friend data.
                    CurrentUser.currentUser?.friends?.removeAll(where: { $0.id == requester.id})

                    print("Document successfully removed!")
                    
                    // Delete current user data from requester's friend collection in firebase.
                    docRef = db.collection("users").document(requester.id)
                    docRef.collection("friends").document(userId).delete() { (error) in
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                        } else {
                            print("Friend document data deleted successfully.")
                        }
                    }
                }
            }
        }
        
        self.requests.removeAll(where: { $0.id == requester.id})
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendTypeArray[segCon.selectedSegmentIndex].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell_8", for: indexPath)  as! FriendTableViewCell
        let dataToShow = friendTypeArray[segCon.selectedSegmentIndex]
        let friend = dataToShow[indexPath.row]
        
        cell.userImageIV.image = friend.profilePic
        cell.userNameLbl.text = friend.fullName
        cell.userEmailLbl.text = friend.email
        
        if segCon.selectedSegmentIndex == 1 {
            cell.declineButton.isHidden = false
            cell.acceptButton.isHidden = false
            
            cell.responseTapped = {(response) in
                print(response)
                
                cell.declineButton.isHidden = true
                cell.acceptButton.isHidden = true
                
                self.setResponse(requester: friend, response: response)
            }
        } else if friend.status == "pending" {
            cell.pendingLbl.isHidden = false
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row for animation purposes.
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
