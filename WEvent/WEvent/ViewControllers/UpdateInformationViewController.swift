//
//  UpdateInformationViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/28/22.
//

import UIKit
import Firebase
import FirebaseAuth

class UpdateInformationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var picIV: CustomImageView!
    @IBOutlet weak var fNameTF: CustomTextField!
    @IBOutlet weak var lNameTF: CustomTextField!
    @IBOutlet weak var emailTF: CustomTextField!
    @IBOutlet weak var passwordTF: CustomTextField!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var activityView: CustomActivityIndicatorView!
    
    var imagePicker = UIImagePickerController()
    var imageData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hideKeyboardWhenTappedAround()
        
        if CurrentUser.currentUser != nil {
            picIV.image = CurrentUser.currentUser?.profilePic
            fNameTF.text = CurrentUser.currentUser?.firstName
            lNameTF.text = CurrentUser.currentUser?.lastName
            emailTF.text = CurrentUser.currentUser?.email
        }
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
        guard let fName = fNameTF.text, !fName.isEmpty,
              let lName = lNameTF.text, !lName.isEmpty,
              let email = emailTF.text, !email.isEmpty
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
        
        // Ensure data has been changed.
        if picIV.image == CurrentUser.currentUser?.profilePic && fName == CurrentUser.currentUser?.firstName && lName == CurrentUser.currentUser?.lastName && email == CurrentUser.currentUser?.email {
            // Set alert title and message.
            alert.title = "Unchanged Data"
            alert.message = "The information that you are trying to submit is unchanged and cannot be updated. Please verify that you have entered new information and try again."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            self.activityView.isHidden = true
            self.activityView.activityIndicator.stopAnimating()
            
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
            
            Auth.auth().currentUser?.updateEmail(to: email) { error in
                // Ensure there are no errors while updating user email.
                guard error == nil
                // Action if error occurs.
                else {
                    // Set alert title and message.
                    alert.title = "Email Update Failed"
                    alert.message = "There was an issue updating your email address. Please try again."
                    
                    // Show alert.
                    self.present(alert, animated: true, completion: nil)
                    
                    self.activityView.isHidden = true
                    self.activityView.activityIndicator.stopAnimating()
                    
                    return
                }
                
                // Update user document in Firebase.
                let db = Firestore.firestore()
                let docId = Auth.auth().currentUser?.uid
                
                db.collection("users").document(docId!).updateData(["firstName": fName, "lastName": lName, "email": email]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Document successfully updated")
                        
                        // Create alert to notify user of successful update.
                        let successAlert = UIAlertController(title: "Success", message: "Account information successfully updated.", preferredStyle: .alert)
                        
                        // Add action to successAlert controller.
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            self.activityView.isHidden = true
                            self.activityView.activityIndicator.stopAnimating()
                            self.dismiss(animated: true, completion: nil)
                        }))
                        
                        // Save user profile picture.
                        if self.imageData != nil {
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
                                                    // Update current user photo.
                                                    CurrentUser.currentUser?.profilePic = self.picIV.image
                                                    
                                                    // Show successAlert.
                                                    self.present(successAlert, animated: true, completion: nil)
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
                        } else {
                            // Show successAlert if photo has not been changed.
                            self.present(successAlert, animated: true, completion: nil)
                        }
                        
                        // Update current user information.
                        CurrentUser.currentUser?.firstName = fName
                        CurrentUser.currentUser?.lastName = lName
                        CurrentUser.currentUser?.email = email
                    }
                }
            }
        })
    }
    
    @IBAction func setPicture(_ sender: UIButton) {
        let getPermissionsDelegate: GetPhotoCameraPermissionsDelegate! = GetImageHelper()
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a Source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                Task.init {
                    if await getPermissionsDelegate.getPhotosPermissions() {
                        let imagePicker = UIImagePickerController()
                        
                        imagePicker.delegate = self
                        imagePicker.sourceType = .photoLibrary
                        imagePicker.allowsEditing = false
                        
                        self.present(imagePicker, animated: true, completion: nil)
                    }
                }
            } else {
                // Create alert.
                let alert = UIAlertController(title: "No Library", message: "Photo library is not available on this device.", preferredStyle: .alert)
                // Add action to alert controller.
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // Show alert.
                self.present(alert, animated: true, completion: nil)
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Task.init {
                    if await getPermissionsDelegate.getCameraPermissions() {
                        let imagePicker = UIImagePickerController()
                        
                        imagePicker.delegate = self
                        imagePicker.sourceType = .camera
                        
                        self.present(imagePicker, animated: true)
                    }
                }
            } else {
                // Create alert.
                let alert = UIAlertController(title: "No Camera", message: "Camera is not available on this device.", preferredStyle: .alert)
                // Add action to alert controller.
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // Show alert.
                self.present(alert, animated: true, completion: nil)
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Resize image
            let targetSize = CGSize(width: 100, height: 100)
            let scaledImg = image.scalePreservingAspectRatio(targetSize: targetSize)
            
            imageData = scaledImg.pngData()
            picIV.image = scaledImg
        }
    }
}
