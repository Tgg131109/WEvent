//
//  CreateEventViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 3/1/22.
//

import UIKit

class CreateEventViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var eventPicIV: UIImageView!
    @IBOutlet weak var eventTitleTF: CustomTextField!
    @IBOutlet weak var eventDateTF: CustomTextField!
    @IBOutlet weak var eventPriceTF: CustomTextField!
    @IBOutlet weak var eventLocationTF: CustomTextField!
    @IBOutlet weak var eventDescriptionTV: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventDescriptionTV.delegate = self

        eventPicIV.layer.cornerRadius = 10
        eventDescriptionTV.layer.cornerRadius = 6
        eventDescriptionTV.layer.borderWidth = 2
        eventDescriptionTV.layer.borderColor = UIColor(red: 194/255, green: 231/255, blue: 250/255, alpha: 1).cgColor
    }
    
    @IBAction func cancelBtnTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if eventDescriptionTV.textColor == .systemGray3 {
            eventDescriptionTV.text = nil
            eventDescriptionTV.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if eventDescriptionTV.text.isEmpty {
            eventDescriptionTV.text = "Event Description"
            eventDescriptionTV.textColor = .systemGray3
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
