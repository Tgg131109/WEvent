//
//  SuccessViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/23/22.
//

import UIKit

class SuccessViewController: UIViewController {

    @IBOutlet weak var picIV: CustomImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.setHidesBackButton(true, animated: true)
        
        if CurrentUser.currentUser != nil {
            picIV.image = CurrentUser.currentUser?.profilePic
        }
    }

    @IBAction func goToHome(_ sender: UIButton) {
        performSegue(withIdentifier: "goToHome", sender: self)
        navigationController?.popToRootViewController(animated: true)
    }
}
