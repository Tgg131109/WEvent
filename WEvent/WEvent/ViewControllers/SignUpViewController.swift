//
//  SignUpViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/21/22.
//

import UIKit
import Firebase
import FirebaseAuth

class SignUpViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var picIV: CustomImageView!
    @IBOutlet weak var fNameTF: CustomTextField!
    @IBOutlet weak var lNameTF: CustomTextField!
    @IBOutlet weak var emailTF: CustomTextField!
    @IBOutlet weak var passwordTF: CustomTextField!
    @IBOutlet weak var password2TF: CustomTextField!
    @IBOutlet weak var signInBtn: UIButton!
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityInd: UIActivityIndicatorView!
    
    var imagePicker = UIImagePickerController()
    var imageData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if view.isHidden {
            view.isHidden.toggle()
        }
    }
    
    @IBAction func signUpBtnTapped(_ sender: UIButton) {
        // Create alert to be displayed if proper conditions are not met.
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        // Add action to alert controller.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Ensure required fields are not empty.
        guard let fName = fNameTF.text, !fName.isEmpty,
              let lName = lNameTF.text, !lName.isEmpty,
              let email = emailTF.text,!email.isEmpty,
              let password = passwordTF.text, !password.isEmpty,
              let password2 = password2TF.text, !password2.isEmpty
        else {
            // Set alert title and message.
            alert.title = "Missing Info"
            alert.message = "All fields must be completed to continue."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        // Validate email.
        if !email.contains("@") {
            // Set alert title and message.
            alert.title = "Invalid Email"
            alert.message = "The email that you have entered is invalid. Please enter a valid email address and try again."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
        }
        
        // Validate passwords.
        if password.count < 6 || password.count > 12 || password != password2 {
            // Set alert title and message.
            alert.title = "Invalid Password"
            alert.message = "Password must be between 6 and 12 characters and passwords must match. Please enter a valid password and try again."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        // Ensure profile picture is selected.
        if self.imageData == nil {
            // Set alert title and message.
            alert.title = "Missing Picture"
            alert.message = "You must select a profile picture to continue. Please make a selection and try again."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        activityInd.startAnimating()
        activityView.isHidden = false
        
        let addDate = Date()
        
        // Create new user account in Firebase.
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            // Ensure there are no errors during account creation.
            guard error == nil
            // Action if error occurs.
            else {
                // Set alert title and message.
                alert.title = "Error"
                alert.message = "Account creation failed. Please try again."
                
                // Show alert.
                self.present(alert, animated: true, completion: nil)
                
                return
            }
                        
            // Add user to user collection in Firebase.
            let db = Firestore.firestore()
            let docId = Auth.auth().currentUser?.uid
            let data: [String: Any] = ["firstName": fName, "lastName": lName, "email": email, "addDate": addDate, "isInvited": false, "recentSearches": [String]()]
            
            db.collection("users").document(docId!).setData(data) { (error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    // Save user profile picture.
                    let storageRef = Storage.storage().reference().child("users").child(docId!).child("profile.png")
                    let metaData = StorageMetadata()
                    
                    metaData.contentType = "image/png"
                    
                    storageRef.putData(self.imageData!, metadata: metaData) { (metaData, error) in
                        if error == nil, metaData != nil {
                            storageRef.downloadURL { url, error in
                                if let url = url {
                                    // Update Firebase authentication profile picture.
                                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                                    
                                    changeRequest?.photoURL = url
                                    changeRequest?.commitChanges(completion: { error in
                                        if error == nil {
                                            // Set current user.
                                            let user = User(profilePic: self.picIV.image, firstName: fName, lastName: lName, email: email, addDate: addDate)
                                            
                                            CurrentUser.currentUser = user
                                            
                                            print("Your account has been created.")
                                            
                                            // Hide views for animation purposes.
                                            self.view.isHidden = true
                                            
                                            // Show SuccessViewController.
                                            self.performSegue(withIdentifier: "goToSuccess", sender: self)
                                            
                                            self.activityView.isHidden = true
                                            self.activityInd.stopAnimating()
                                        } else {
                                            // Print error if update fails.
                                            print(error!.localizedDescription)
                                        }
                                    })
                                }
                            }
                        } else {
                            // Print error if upload fails.
                            print(error?.localizedDescription ?? "There was an issue uploading photo.")
                        }
                    }
                }
            }
        }
    }

    @IBAction func setPicture(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false

            present(imagePicker, animated: true, completion: nil)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageData = image.pngData()
            
            picIV.image = image
        }

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
