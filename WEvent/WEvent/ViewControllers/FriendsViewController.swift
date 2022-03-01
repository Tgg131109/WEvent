//
//  FriendsViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/28/22.
//

import UIKit

class FriendsViewController: UIViewController {

    @IBOutlet weak var segCon: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        segCon.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1)], for: .selected)
    }
    
    @IBAction func cancelBtnTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
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
