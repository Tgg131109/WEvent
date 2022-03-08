//
//  CustomCollectionViewCell.swift
//  WEvent
//
//  Created by Toby Gamble on 2/24/22.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var eventImageIV: UIImageView!
    @IBOutlet weak var eventDateLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var eventAddressLbl: UILabel!
}

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageIV: UIImageView!
}
