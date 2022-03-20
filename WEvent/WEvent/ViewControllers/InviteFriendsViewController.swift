//
//  InviteFriendsViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 3/10/22.
//

import UIKit
import Firebase
import Kingfisher

class InviteFriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inviteBtn: UIButton!
    
    let db = Firestore.firestore()
    
    var event: Event?
    var friends = [Friend]()
    var friendIds = [String]()
    var invitedFriends = [Friend]()
    
    var eventDataDelegate: EventDataDelegate!
    
    var updateEvent: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friends = CurrentUser.currentUser?.friends?.filter({ $0.status != "requested" }) ?? [Friend]()
        eventDataDelegate = FirebaseHelper()

        if let eId = event?.id {
            for friend in friends {
                // Check if any friends already have plans to attend or have been invited to this event an exclude them from list if so.
                db.collection("users").document(friend.id).collection("events").document(eId).getDocument { (eDoc, error) in
                    if let eDoc = eDoc, eDoc.exists {
                        guard let eventData = eDoc.data(),
                              let groupId = eventData["groupId"] as? String
                        else {
                            print("There was an error setting event data from invite")
                            return
                        }
                        
                        if !groupId.isEmpty {
                            print("Friend is already attending or invited to this event.")
                            self.friends.removeAll(where: { $0.id == friend.id})
                            self.tableView.reloadData()
                        }
                    } else {
                        print("Invite document does not exist")
                    }
                }
            }
        }
        
        tableView.reloadData()
    }
    
    @IBAction func cancelBtnTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func inviteBtnTapped(_ sender: UIButton) {
        saveInvitesToFirebase()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    private func saveInvitesToFirebase() {
        if let eId = event?.id, let gId = event?.groupId, let index = CurrentUser.currentUser?.userEvents?.firstIndex(where: { $0.id == eId }) {
            for friend in invitedFriends {
                // Update event properties and update current user's events to match.
                self.event?.pendingIds.append(friend.id)
                
                CurrentUser.currentUser?.userEvents?[index] = self.event!
                updateEvent?()
                
                let ref = db.collection("users").document(friend.id).collection("events").document(eId)
                // Check if any friends already have this event saved and update document if so.
                ref.getDocument { (eDoc, error) in
                    if let eDoc = eDoc, eDoc.exists {
                        eDoc.reference.updateData(["groupId": gId, "status": "invited"]) { err in
                            if let err = err {
                                print("Error updating friend event: \(err)")
                            } else {
                                print("Friend event successfully updated")
                            }
                        }
                    } else {
                        print("Add event document for friend")
                        let data: [String: Any] = ["groupId": gId, "status": "invited", "isCreated": false, "isFavorite": false]
                        
                        ref.setData(data) { (error) in
                            if let error = error {
                                print("Error: \(error.localizedDescription)")
                            } else {
                                print("User favorite event added with ID: \(eId)")
                            }
                        }
                    }
                    
                    // Add friend id to group's pending id's array.
                    self.db.collection("groups").document(gId).updateData(["pendingIds": FieldValue.arrayUnion([friend.id])]) { error in
                        if let error = error {
                            print("Error updating document: \(error)")
                        } else {
                            print("Group pendingIds successfully updated")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell_10", for: indexPath)  as! FriendTableViewCell
        let friend = friends[indexPath.row]
        
        cell.userImageIV.kf.indicatorType = .activity
        cell.userImageIV.kf.setImage(with: URL(string: friend.picUrl ?? ""), placeholder: UIImage(named: "logo_placeholder"), options: [.transition(.fade(1))], completionHandler: { result in
            switch result {
            case .success(let value):
                self.friends[indexPath.row].profilePic = value.image
                friend.profilePic = value.image
                
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
        
        cell.checkTapped = {(checkButton) in
            checkButton.isSelected.toggle()
            checkButton.tintColor = checkButton.isSelected ? UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1) : .systemGray
            
            if checkButton.isSelected {
                self.invitedFriends.append(friend)
            } else {
                self.invitedFriends.removeAll(where: { $0.id == friend.id})
            }
            
            self.inviteBtn.setTitle(self.invitedFriends.count > 1 ? "Send Invites" : "Send Invite", for: .normal)
            self.inviteBtn.isEnabled = !self.invitedFriends.isEmpty
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row for animation purposes.
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
