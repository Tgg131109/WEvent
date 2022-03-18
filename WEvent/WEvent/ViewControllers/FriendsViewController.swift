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
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(msgLblTapped(_:)))
        
        noFriendsLbl.addGestureRecognizer(tapRecognizer)
        noFriendsLbl.layer.cornerRadius = 6
        noFriendsLbl.layer.masksToBounds = true
        
        segCon.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1)], for: .selected)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let allFriends = CurrentUser.currentUser?.friends ?? [Friend]()
        
        friends = allFriends.filter({ $0.status != "requested" })
        requests = allFriends.filter({ $0.status == "requested" })
        
        friendTypeArray = [friends, requests]
        
        noFriendsLbl.isHidden = !friends.isEmpty
        
        tableView.reloadData()
    }
    
    @objc func msgLblTapped(_ sender: Any) {
        performSegue(withIdentifier: "goToAddFriends", sender: self)
    }
    
    @IBAction func cancelBtnTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func segConChanged(_ sender: UISegmentedControl) {
        if segCon.selectedSegmentIndex == 0 {
            noRequestsLbl.isHidden = true
            noFriendsLbl.isHidden = !friends.isEmpty
        } else {
            noFriendsLbl.isHidden = true
            noRequestsLbl.isHidden = !requests.isEmpty
        }
        
        self.tableView.reloadSections(IndexSet([0]), with: .fade)
    }

    private func setResponse(requester: Friend, response: String) {
        let db = Firestore.firestore()
        let userId = Auth.auth().currentUser!.uid
        var docRef = db.collection("users").document(userId)
        
        if response == "accepted" {
            // Update local friend data.
            CurrentUser.currentUser?.friends?.first(where: { $0.id == requester.id})?.status = response
            requester.status = response
            
            self.friends.append(requester)
            
            // Find document in Firebase and update status field.
            docRef.collection("friends").document(requester.id).updateData(["status": response]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
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
            // Update local friend data.
            CurrentUser.currentUser?.friends?.removeAll(where: { $0.id == requester.id})
            
            // Remove friend from Firebase.
            docRef.collection("friends").document(requester.id).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
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
        self.friendTypeArray = [friends, requests]
        self.navigationController?.tabBarController?.tabBar.items?[3].badgeValue = "\(self.requests.count)"
        self.tableView.reloadSections(IndexSet([0]), with: .fade)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendTypeArray[segCon.selectedSegmentIndex].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell_8", for: indexPath)  as! FriendTableViewCell
        let dataToShow = friendTypeArray[segCon.selectedSegmentIndex]
        let friend = dataToShow[indexPath.row]
        
        cell.userImageIV.kf.indicatorType = .activity
        cell.userImageIV.kf.setImage(with: URL(string: friend.picUrl ?? ""), placeholder: UIImage(named: "logo_placeholder"), options: [.transition(.fade(1))], completionHandler: { result in
            switch result {
            case .success(let value):
                dataToShow[indexPath.row].profilePic = value.image
                friend.profilePic = value.image
                
                if self.segCon.selectedSegmentIndex == 0 {
                    self.friends[indexPath.row].profilePic = value.image
                } else {
                    if !self.requests.isEmpty {
                        self.requests[indexPath.row].profilePic = value.image
                    }
                }

                CurrentUser.currentUser?.friends?.first(where: { $0.id == friend.id})?.profilePic = value.image
                break
                
            case .failure(let error):
                if !error.isTaskCancelled && !error.isNotCurrentTask {
                    print("Error getting image: \(error)")
                }
                break
            }
        })
        
        cell.userNameLbl.text = friend.fullName
        cell.userEmailLbl.text = friend.email
        
        if segCon.selectedSegmentIndex == 1 {
            cell.declineButton.isHidden = false
            cell.acceptButton.isHidden = false
            cell.pendingLbl.isHidden = true
            
            cell.responseTapped = {(response) in
                cell.declineButton.isHidden = true
                cell.acceptButton.isHidden = true
                
                self.setResponse(requester: friend, response: response)
            }
        } else {
            cell.declineButton.isHidden = true
            cell.acceptButton.isHidden = true
            cell.pendingLbl.isHidden = !(friend.status == "pending")
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
