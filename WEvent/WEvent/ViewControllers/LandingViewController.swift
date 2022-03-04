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

    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLbl: UILabel!
    
    var signIn = false
    var userDataDelegate: UserDataDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Check if user is already logged in and retrieve user information from Firebase if so.
        if Auth.auth().currentUser != nil {
            activityIndicator.startAnimating()
            statusLbl.text = "Retrieving your data..."
            
            userDataDelegate = FirebaseHelper()
            
            Task.init {
                do {
                    try await userDataDelegate.getCriticalData()
                } catch {
                    // .. handle error
                    print("There was an error getting critical user data.")
                }
            
            goToSignIn()
            
                do {
                    try await userDataDelegate.getBackgroundData()
                } catch {
                    // .. handle error
                    print("There was an error getting background user data.")
                }
            }
        } else {
            goToSignIn()
        }
    }
    
    func goToSignIn() {
        activityIndicator.stopAnimating()
        activityView.isHidden = true
        
        // Show SignInViewController
        signIn = true
        self.performSegue(withIdentifier: "goToSignIn", sender: self)
    }

    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return signIn
    }
}
