//
//  ProfileViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/23/22.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    @IBOutlet weak var picIV: CustomImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if CurrentUser.currentUser != nil {
            displayUserData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Update data to display if it has been changed.
        if let currentUser = CurrentUser.currentUser {
            if currentUser.profilePic != picIV.image || currentUser.fullName != nameLbl.text || currentUser.email != emailLbl.text {
                displayUserData()
            }
        }
    }
    
    @IBAction func signOutBtnTapped(_ sender: UIButton) {
        // Create alert.
        let alert = UIAlertController(title: "Sign Out?", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        
        // Add actions to alert controller.
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { action in
            // Sign user out of Firebase.
            do {
              try Auth.auth().signOut()
            } catch let signOutError as NSError {
              print("Error signing out: %@", signOutError)
            }

            // Ensure user is signed out.
            if FirebaseAuth.Auth.auth().currentUser == nil {
                CurrentUser.currentUser = nil
                CurrentLocation.location = nil
                CurrentLocation.preferredLocation = nil
                // Dismiss entire tabController and return to SignInViewController.
                self.dismiss(animated: true, completion: nil)
            }
        }))
        
        // Show alert.
        self.present(alert, animated: true, completion: nil)
    }

    func displayUserData() {
        picIV.image = CurrentUser.currentUser?.profilePic
        nameLbl.text = CurrentUser.currentUser?.fullName
        emailLbl.text = CurrentUser.currentUser?.email
    }
}
