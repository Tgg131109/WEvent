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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
