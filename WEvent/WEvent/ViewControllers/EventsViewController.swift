//
//  EventsViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/23/22.
//

import UIKit

class EventsViewController: UIViewController {

    @IBOutlet weak var segCon: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segCon.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1)], for: .selected)
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
