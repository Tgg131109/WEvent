//
//  UpdatePasswordViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/28/22.
//

import UIKit
import FirebaseAuth

class UpdatePasswordViewController: UIViewController {

    @IBOutlet weak var passwordTF: CustomTextField!
    @IBOutlet weak var newPasswordTF: CustomTextField!
    @IBOutlet weak var newPassword2TF: CustomTextField!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var activityView: CustomActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func cancelBtnTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func passwordTFChanged(_ sender: CustomTextField) {
        saveBtn.isEnabled = passwordTF.hasText
    }
    
    @IBAction func saveBtnTapped(_ sender: UIButton) {
        // Create alert to be displayed if proper conditions are not met.
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        // Add action to alert controller.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Ensure required fields are not empty.
        guard let password = passwordTF.text, !password.isEmpty,
              let newPassword = newPasswordTF.text, !newPassword.isEmpty,
              let newPassword2 = newPassword2TF.text, !newPassword2.isEmpty
        else {
            // Set alert title and message.
            alert.title = "Missing Info"
            alert.message = "All fields must be completed to continue."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        // Validate passwords.
        if newPassword.count < 6 || newPassword.count > 12 || newPassword != newPassword2 {
            // Set alert title and message.
            alert.title = "Invalid Password"
            alert.message = "Password must be between 6 and 12 characters and passwords must match. Please enter a valid password and try again."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        self.activityView.activityIndicator.startAnimating()
        self.activityView.isHidden = false
        
        // Reauthenticate user.
        let credential = EmailAuthProvider.credential(withEmail: CurrentUser.currentUser!.email, password: passwordTF.text!)
        
        Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (result, error) in
            // Ensure there are no errors while reauthenticating.
            guard error == nil
            // Action if error occurs.
            else {
                // Set alert title and message.
                alert.title = "Verification Failed"
                alert.message = "There was an issue verifying your credentials. Please re-enter your password and try again."
                
                // Show alert.
                self.present(alert, animated: true, completion: nil)
                
                self.activityView.isHidden = true
                self.activityView.activityIndicator.stopAnimating()
                
                return
            }
            
            Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                // Ensure there are no errors while updating user password.
                guard error == nil
                // Action if error occurs.
                else {
                    // Set alert title and message.
                    alert.title = "Password Update Failed"
                    alert.message = "There was an issue updating your password. Please try again."
                    
                    // Show alert.
                    self.present(alert, animated: true, completion: nil)
                    
                    self.activityView.isHidden = true
                    self.activityView.activityIndicator.stopAnimating()
                    
                    return
                }
                
                // Create alert to notify user of successful update.
                let successAlert = UIAlertController(title: "Success", message: "Your password has been successfully updated.", preferredStyle: .alert)
                
                // Add action to successAlert controller.
                successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    self.activityView.isHidden = true
                    self.activityView.activityIndicator.stopAnimating()
                    self.dismiss(animated: true, completion: nil)
                }))
                
                // Show alert.
                self.present(successAlert, animated: true, completion: nil)
            }
        })
    }
}
