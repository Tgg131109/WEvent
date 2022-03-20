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
    @IBOutlet weak var userIV: CustomImageView!
}

class ZoomImageCVCell: UICollectionViewCell, UIScrollViewDelegate {
    @IBOutlet weak var imageIV: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 4.0
        self.scrollView.delegate = self
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageIV
    }
}
