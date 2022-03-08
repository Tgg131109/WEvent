//
//  CustomTableViewCell.swift
//  WEvent
//
//  Created by Toby Gamble on 2/24/22.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var eventImageIV: UIImageView!
    @IBOutlet weak var eventDateLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var eventAddressLbl: UILabel!
    @IBOutlet weak var favButton: UIButton!
    
    var favTapped: ((UIButton) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func favBtnTapped(_ sender: UIButton) {
        favTapped?(sender)
    }
}

class CVTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

class FriendTableViewCell: UITableViewCell {

    @IBOutlet weak var userImageIV: CustomImageView!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var userEmailLbl: UILabel!
    @IBOutlet weak var pendingLbl: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    var checkTapped: ((UIButton) -> Void)?
    var responseTapped: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func checkBtnTapped(_ sender: UIButton) {
        checkTapped?(sender)
    }
    
    @IBAction func declineBtnTapped(_ sender: UIButton) {
        responseTapped?("declined")
    }
    
    @IBAction func acceptBtnTapped(_ sender: UIButton) {
        responseTapped?("accepted")
    }
}
