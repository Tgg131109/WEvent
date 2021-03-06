//
//  SignInViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/20/22.
//

import UIKit
import Firebase
import FirebaseAuth

class SignInViewController: UIViewController {

    @IBOutlet weak var activityView: CustomActivityIndicatorView!
    @IBOutlet weak var emailField: CustomTextField!
    @IBOutlet weak var passwordField: CustomTextField!
    @IBOutlet weak var signInBtn: UIButton!
//    @IBOutlet weak var forgotPasswordBtn: UIButton!
    @IBOutlet weak var facebookBtn: UIButton!
    @IBOutlet weak var googleBtn: UIButton!
//    @IBOutlet weak var signUpBtn: UIButton!
    
    var userDataDelegate: UserDataDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        view.isHidden = true
        
        if CurrentUser.currentUser != nil {
            // Show HomeViewController.
            self.performSegue(withIdentifier: "goToHome", sender: self)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if Auth.auth().currentUser == nil && view.isHidden {
            view.isHidden.toggle()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if Auth.auth().currentUser == nil {
            view.isHidden = true
        }
    }
    
    @IBAction func forgotPasswordBtnTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Need Help?", message: "Enter the email address associated with your account. If it is found, an email will be sent with instructions on how to reset your password.", preferredStyle: .alert)
        // Add text field to alert controller.
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        })
        
        // Add actions to alert controller.
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let submitAction = UIAlertAction(title: "Submit", style: .default, handler: { action in
            guard let email = alert.textFields?.first?.text else { return }
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if error != nil {
                    print("There was an error")
                } else {
                    print("Reset instructions sent")
                }
            }
        })
        
        submitAction.isEnabled = false
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: alert.textFields?.first, queue: .main) { (notification) -> Void in
            guard let inputStr = alert.textFields?.first?.text else { return }
            submitAction.isEnabled = self.isValidEmail(testStr: inputStr) && !inputStr.isEmpty
        }
        
        alert.addAction(submitAction)
        
        // Show alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func signInBtnTapped(_ sender: UIButton) {
        // Create alert to be displayed if proper conditions are not met.
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        // Add action to alert controller.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Ensure required fields are not empty.
        guard let email = emailField.text, !email.isEmpty, self.isValidEmail(testStr: email),
              let password = passwordField.text, !password.isEmpty
        else {
            // Set alert title and message.
            alert.title = "Missing Info"
            alert.message = "All fields must be completed to continue."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        activityView.activityIndicator.startAnimating()
        activityView.statusLbl.text = "Retrieving your data..."
        activityView.isHidden = false
        passwordField.text = ""
        
        // Use Firebase to authenticate user if signing in with email and password.
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {result, error in
            // Ensure there are no errors while signing in.
            guard error == nil
            // Action if error occurs.
            else {
                // Set alert title and message.
                alert.title = "Sign In Failed"
                alert.message = "The email or password that you entered is incorrect. Please enter the correct email and password and try again."
                
                // Show alert.
                self.present(alert, animated: true, completion: nil)
                
                self.activityView.isHidden = true
                self.activityView.activityIndicator.stopAnimating()
                
                return
            }
            
            print("You have been signed in.")

            self.getCurrentUserData()
        })
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        if let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx) as NSPredicate? {
            return emailTest.evaluate(with: testStr)
        }
        return false
    }
    
    func getCurrentUserData() {
        userDataDelegate = FirebaseHelper()
        
        Task.init {
            do {
                try await userDataDelegate.getCriticalData()
            } catch {
                // .. handle error
                print("There was an error getting critical user data.")
            }
            
            activityView.isHidden = true
            activityView.activityIndicator.stopAnimating()

            // Show HomeViewController.
            self.performSegue(withIdentifier: "goToHome", sender: self)
            
            do {
                try await userDataDelegate.getBackgroundData()
            } catch {
                // .. handle error
                print("There was an error getting background user data.")
            }
        }
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}
