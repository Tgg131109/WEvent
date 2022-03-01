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
        // Sign user out of Firebase.
        do {
          try Auth.auth().signOut()
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }

        // Ensure user is signed out.
        if FirebaseAuth.Auth.auth().currentUser == nil {
            // Dismiss entire tabController and return to SignInViewController.
            self.dismiss(animated: true, completion: nil)
        }
    }

    func displayUserData() {
        picIV.image = CurrentUser.currentUser?.profilePic
        nameLbl.text = CurrentUser.currentUser?.fullName
        emailLbl.text = CurrentUser.currentUser?.email
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
